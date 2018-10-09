# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Lookahead do
  module LookaheadTest
    DATA = [
      OpenStruct.new(name: "Cardinal", is_waterfowl: false, similar_species_names: ["Scarlet Tanager"]),
      OpenStruct.new(name: "Scarlet Tanager", is_waterfowl: false, similar_species_names: ["Cardinal"]),
      OpenStruct.new(name: "Great Egret", is_waterfowl: false, similar_species_names: ["Great Blue Heron"]),
      OpenStruct.new(name: "Great Blue Heron", is_waterfowl: true, similar_species_names: ["Great Egret"]),
    ]

    def DATA.find_by_name(name)
      DATA.find { |b| b.name == name }
    end

    class BirdSpecies < GraphQL::Schema::Object
      field :name, String, null: false
      field :is_waterfowl, Boolean, null: false
      field :similar_species, [BirdSpecies], null: false,
        extras: [:lookahead]

      def similar_species(lookahead:)
        if lookahead.selects?(:__typename)
          context[:lookahead_typename] += 1
        end

        object.similar_species_names.map { |n| DATA.find_by_name(n) }
      end
    end

    class Query < GraphQL::Schema::Object
      field :find_bird_species, BirdSpecies, null: true do
        argument :by_name, String, required: true
      end

      def find_bird_species(by_name:)
        DATA.find_by_name(by_name)
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
    # Cause everything to be loaded
    # TODO remove this
    Schema.graphql_definition
  end

  describe "looking ahead" do
    let(:document) {
      GraphQL.parse <<-GRAPHQL
      query($name: String!){
        findBirdSpecies(byName: $name) {
          name
          similarSpecies {
            likesWater: isWaterfowl
          }
        }
        t: __typename
      }
      GRAPHQL
    }
    let(:query) {
      GraphQL::Query.new(LookaheadTest::Schema, document: document, variables: { name: "Cardinal" })
    }

    it "has a good test setup" do
      res = query.result
      assert_equal [false], res["data"]["findBirdSpecies"]["similarSpecies"].map { |s| s["likesWater"] }
    end

    it "can detect fields on objects with symbol or string" do
      ast_node = document.definitions.first.selections.first
      owner = LookaheadTest::BirdSpecies
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_node: ast_node, owner: owner)
      assert_equal true, lookahead.selects?("similarSpecies")
      assert_equal true, lookahead.selects?(:similar_species)
      assert_equal false, lookahead.selects?("isWaterfowl")
      assert_equal false, lookahead.selects?(:is_waterfowl)
    end

    it "detects by name, not by alias" do
      ast_node = document.definitions.first
      owner = LookaheadTest::Query
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_node: ast_node, owner: owner)
      assert_equal true, lookahead.selects?("__typename")
    end

    describe "constraints by arguments" do
      let(:lookahead) do
        ast_node = document.definitions.first
        owner = LookaheadTest::Query
        GraphQL::Execution::Lookahead.new(query: query, ast_node: ast_node, owner: owner)
      end

      it "is true without constraints" do
        assert_equal true, lookahead.selects?("findBirdSpecies")
      end

      it "is true when all given constraints are satisfied" do
        assert_equal true, lookahead.selects?(:find_bird_species, arguments: { by_name: "Cardinal" })
        assert_equal true, lookahead.selects?("findBirdSpecies", arguments: { "byName" => "Cardinal" })
      end

      it "is true when no constraints are given" do
        assert_equal true, lookahead.selects?(:find_bird_species, arguments: {})
        assert_equal true, lookahead.selects?("__typename", arguments: {})
      end

      it "is false when some given constraints aren't satisfied" do
        assert_equal false, lookahead.selects?(:find_bird_species, arguments: { by_name: "Chickadee" })
        assert_equal false, lookahead.selects?(:find_bird_species, arguments: { by_name: "Cardinal", other: "Nonsense" })
      end

      describe "with literal values" do
        let(:document) {
          GraphQL.parse <<-GRAPHQL
          {
            findBirdSpecies(byName: "Great Blue Heron") {
              isWaterfowl
            }
          }
          GRAPHQL
        }

        it "works" do
          assert_equal true, lookahead.selects?(:find_bird_species, arguments: { by_name: "Great Blue Heron" })
        end
      end
    end

    it "can do a chained lookahead" do
      ast_node = document.definitions.first
      owner = LookaheadTest::Query
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_node: ast_node, owner: owner)
      next_lookahead = lookahead.selection(:find_bird_species, arguments: { by_name: "Cardinal" })
      assert_equal true, next_lookahead.selected?
      nested_selection = next_lookahead.selection(:similar_species).selection(:is_waterfowl, arguments: {})
      assert_equal true, nested_selection.selected?
      assert_equal false, next_lookahead.selection(:similar_species).selection(:name).selected?
    end

    it "can detect fields on lists with symbol or string" do
      ast_node = document.definitions.first
      owner = LookaheadTest::Query
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_node: ast_node, owner: owner)
      assert_equal true, lookahead.selection(:find_bird_species).selection(:similar_species).selection(:is_waterfowl).selected?
      assert_equal true, lookahead.selection("findBirdSpecies").selection("similarSpecies").selection("isWaterfowl").selected?
    end
  end

  describe "in queries" do
    it "can be an extra" do
      query_str = <<-GRAPHQL
      {
        cardinal: findBirdSpecies(byName: "Cardinal") {
          similarSpecies { __typename }
        }
        scarletTanager: findBirdSpecies(byName: "ScarletTanager") {
          similarSpecies { name }
        }
        greatBlueHeron: findBirdSpecies(byName: "Great Blue Heron") {
          similarSpecies { __typename }
        }
      }
      GRAPHQL
      context = {lookahead_typename: 0}
      res = LookaheadTest::Schema.execute(query_str, context: context)
      refute res.key?("errors")
      assert_equal 2, context[:lookahead_typename]
    end
  end
end
