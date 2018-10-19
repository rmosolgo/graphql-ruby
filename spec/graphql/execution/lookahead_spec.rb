# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Lookahead do
  module LookaheadTest
    DATA = [
      OpenStruct.new(name: "Cardinal", is_waterfowl: false, similar_species_names: ["Scarlet Tanager"], genus: OpenStruct.new(latin_name: "Piranga")),
      OpenStruct.new(name: "Scarlet Tanager", is_waterfowl: false, similar_species_names: ["Cardinal"], genus: OpenStruct.new(latin_name: "Cardinalis")),
      OpenStruct.new(name: "Great Egret", is_waterfowl: false, similar_species_names: ["Great Blue Heron"], genus: OpenStruct.new(latin_name: "Ardea")),
      OpenStruct.new(name: "Great Blue Heron", is_waterfowl: true, similar_species_names: ["Great Egret"], genus: OpenStruct.new(latin_name: "Ardea")),
    ]

    def DATA.find_by_name(name)
      DATA.find { |b| b.name == name }
    end

    class BirdGenus < GraphQL::Schema::Object
      field :latin_name, String, null: false
    end

    class BirdSpecies < GraphQL::Schema::Object
      field :name, String, null: false
      field :is_waterfowl, Boolean, null: false
      field :similar_species, [BirdSpecies], null: false

      def similar_species
        object.similar_species_names.map { |n| DATA.find_by_name(n) }
      end

      field :genus, BirdGenus, null: false,
        extras: [:lookahead]

      def genus(lookahead:)
        if lookahead.selects?(:latin_name)
          context[:lookahead_latin_name] += 1
        end
        object.genus
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
      field = LookaheadTest::Query.fields["findBirdSpecies"]
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], field: field)
      assert_equal true, lookahead.selects?("similarSpecies")
      assert_equal true, lookahead.selects?(:similar_species)
      assert_equal false, lookahead.selects?("isWaterfowl")
      assert_equal false, lookahead.selects?(:is_waterfowl)
    end

    it "detects by name, not by alias" do
      ast_node = document.definitions.first
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], root_type: LookaheadTest::Query)
      assert_equal true, lookahead.selects?("__typename")
    end

    describe "constraints by arguments" do
      let(:lookahead) do
        ast_node = document.definitions.first
        GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], root_type: LookaheadTest::Query)
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
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], root_type: LookaheadTest::Query)
      next_lookahead = lookahead.selection(:find_bird_species, arguments: { by_name: "Cardinal" })
      assert_equal true, next_lookahead.selected?
      nested_selection = next_lookahead.selection(:similar_species).selection(:is_waterfowl, arguments: {})
      assert_equal true, nested_selection.selected?
      assert_equal false, next_lookahead.selection(:similar_species).selection(:name).selected?
    end

    it "can detect fields on lists with symbol or string" do
      ast_node = document.definitions.first
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], root_type: LookaheadTest::Query)
      assert_equal true, lookahead.selection(:find_bird_species).selection(:similar_species).selection(:is_waterfowl).selected?
      assert_equal true, lookahead.selection("findBirdSpecies").selection("similarSpecies").selection("isWaterfowl").selected?
    end

    describe "merging branches and fragments" do
      let(:document) {
        GraphQL.parse <<-GRAPHQL
        {
          findBirdSpecies(name: "Cardinal") {
            similarSpecies {
              __typename
            }
          }
          ...F
          ... {
            findBirdSpecies(name: "Cardinal") {
              similarSpecies {
                isWaterfowl
              }
            }
          }
        }

        fragment F on Query {
          findBirdSpecies(name: "Cardinal") {
            similarSpecies {
              name
            }
          }
        }
        GRAPHQL
      }

      it "finds selections using merging" do
        ast_node = document.definitions.first
        lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], root_type: LookaheadTest::Query)
        merged_lookahead = lookahead.selection(:find_bird_species).selection(:similar_species)
        assert merged_lookahead.selects?(:__typename)
        assert merged_lookahead.selects?(:is_waterfowl)
        assert merged_lookahead.selects?(:name)
      end
    end
  end

  describe "in queries" do
    it "can be an extra" do
      query_str = <<-GRAPHQL
      {
        cardinal: findBirdSpecies(byName: "Cardinal") {
          genus { __typename }
        }
        scarletTanager: findBirdSpecies(byName: "Scarlet Tanager") {
          genus { latinName }
        }
        greatBlueHeron: findBirdSpecies(byName: "Great Blue Heron") {
          genus { latinName }
        }
      }
      GRAPHQL
      context = {lookahead_latin_name: 0}
      res = LookaheadTest::Schema.execute(query_str, context: context)
      refute res.key?("errors")
      assert_equal 2, context[:lookahead_latin_name]
    end
  end

  describe '#selections' do
    let(:document) {
      GraphQL.parse <<-GRAPHQL
        query {
          findBirdSpecies(byName: "Laughing Gull") {
            name
            similarSpecies {
              likesWater: isWaterfowl
            }
          }
        }
      GRAPHQL
    }

    def query(doc = document)
      GraphQL::Query.new(LookaheadTest::Schema, document: document)
    end

    it "provides a list of all selections" do
      ast_node = document.definitions.first.selections.first
      field = LookaheadTest::Query.fields["findBirdSpecies"]
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], field: field)
      assert_equal lookahead.selections.map(&:name), [:name, :similar_species]
    end

    it "filters outs selections which do not match arguments" do
      ast_node = document.definitions.first
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], root_type: LookaheadTest::Query)
      arguments = { by_name: "Cardinal" }

      assert_equal lookahead.selections(arguments: arguments).map(&:name), []
    end

    it "includes selections which match arguments" do
      ast_node = document.definitions.first
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], root_type: LookaheadTest::Query)
      arguments = { by_name: "Laughing Gull" }

      assert_equal lookahead.selections(arguments: arguments).map(&:name), [:find_bird_species]
    end

    it 'handles duplicate selections' do
      doc = GraphQL.parse <<-GRAPHQL
        query {
          findBirdSpecies(byName: "Laughing Gull") {
            name
          }

          findBirdSpecies(byName: "Laughing Gull") {
            similarSpecies {
              likesWater: isWaterfowl
            }
          }
        }
      GRAPHQL

      ast_node = doc.definitions.first
      lookahead = GraphQL::Execution::Lookahead.new(query: query(doc), ast_nodes: [ast_node], root_type: LookaheadTest::Query)

      assert_equal [:find_bird_species], lookahead.selections.map(&:name), "Selections are merged"
      assert_equal [:name, :similar_species], lookahead.selections.first.selections.map(&:name), "Subselections are merged"
    end

    it "works for missing selections" do
      ast_node = document.definitions.first.selections.first
      field = LookaheadTest::Query.fields["findBirdSpecies"]
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], field: field)
      null_lookahead = lookahead.selection(:genus)
      # This is an implementation detail, but I want to make sure the test is set up right
      assert_instance_of GraphQL::Execution::Lookahead::NullLookahead, null_lookahead
      assert_equal [], null_lookahead.selections
    end
  end
end
