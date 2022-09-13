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

    module Node
      include GraphQL::Schema::Interface
      field :id, ID, null: false
    end

    class BirdGenus < GraphQL::Schema::Object
      implements Node
      field :name, String, null: false
      field :latin_name, String, null: false
      field :id, ID, null: false, method: :latin_name
    end

    class BirdSpecies < GraphQL::Schema::Object
      implements Node
      field :name, String, null: false
      field :id, ID, null: false, method: :name
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

    class PlantSpecies < GraphQL::Schema::Object
      implements Node
      field :name, String, null: false
      field :id, ID, null: false, method: :name
      field :is_edible, Boolean, null: false
    end

    class Species < GraphQL::Schema::Union
      possible_types BirdSpecies, PlantSpecies
    end

    class Query < GraphQL::Schema::Object
      field :find_bird_species, BirdSpecies do
        argument :by_name, String
      end

      def find_bird_species(by_name:)
        DATA.find_by_name(by_name)
      end

      field :node, Node do
        argument :id, ID
      end

      def node(id:)
        if (node = DATA.find_by_name(id))
          node
        else
          DATA.map { |d| d.genus }.select { |g| g.name == id }
        end
      end

      field :species, Species do
        argument :id, ID
      end

      def species(id:)
        DATA.find_by_name(id)
      end
    end

    class LookaheadInstrumenter
      def self.before_query(query)
        query.context[:root_lookahead_selections] = query.lookahead.selections
      end

      def self.after_query(q)
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      instrument :query, LookaheadInstrumenter
    end
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
      lookahead = query.lookahead.selection("findBirdSpecies")
      assert_equal true, lookahead.selects?("similarSpecies")
      assert_equal true, lookahead.selects?(:similar_species)
      assert_equal false, lookahead.selects?("isWaterfowl")
      assert_equal false, lookahead.selects?(:is_waterfowl)
    end

    it "detects by name, not by alias" do
      assert_equal true, query.lookahead.selects?("__typename")
    end

    describe "on unions" do
      let(:document) {
        GraphQL.parse <<-GRAPHQL
        {
          species(id: "Cardinal") {
            ... on BirdSpecies {
              name
              isWaterfowl
            }
            ... on PlantSpecies {
              name
              isEdible
            }
          }
        }
        GRAPHQL
      }

      it "works" do
        lookahead = query.lookahead.selection(:species)
        assert lookahead.selects?(:name)
        assert_equal [:name, :is_waterfowl, :name, :is_edible], lookahead.selections.map(&:name)
      end

      it "works with different selected types" do
        lookahead = query.lookahead.selection(:species)
        # Both have `name`
        assert lookahead.selects?(:name, selected_type: LookaheadTest::BirdSpecies)
        assert lookahead.selects?(:name, selected_type: LookaheadTest::PlantSpecies)
        # Only birds have `isWaterfowl`
        assert lookahead.selects?(:is_waterfowl, selected_type: LookaheadTest::BirdSpecies)
        refute lookahead.selects?(:is_waterfowl, selected_type: LookaheadTest::PlantSpecies)
        # Only plants have `isEdible`
        refute lookahead.selects?(:is_edible, selected_type: LookaheadTest::BirdSpecies)
        assert lookahead.selects?(:is_edible, selected_type: LookaheadTest::PlantSpecies)
      end
    end

    describe "fields on interfaces" do
      let(:document) {
        GraphQL.parse <<-GRAPHQL
        query {
          node(id: "Cardinal") {
            id
            ... on BirdSpecies {
              name
            }
            ...Other
          }
        }
        fragment Other on BirdGenus {
          latinName
        }
        GRAPHQL
      }

      it "finds fields on object types and interface types" do
        node_lookahead = query.lookahead.selection("node")
        assert_equal [:id, :name, :latin_name], node_lookahead.selections.map(&:name)
      end
    end

    describe "inspect" do
      it "works for root lookaheads" do
        assert_includes query.lookahead.inspect, "#<GraphQL::Execution::Lookahead @root_type="
      end

      it "works for field lookaheads" do
        assert_includes query.lookahead.selection(:find_bird_species).inspect, "#<GraphQL::Execution::Lookahead @field="
      end
    end

    describe "constraints by arguments" do
      let(:lookahead) do
        query.lookahead
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
      next_lookahead = query.lookahead.selection(:find_bird_species, arguments: { by_name: "Cardinal" })
      assert_equal true, next_lookahead.selected?
      nested_selection = next_lookahead.selection(:similar_species).selection(:is_waterfowl, arguments: {})
      assert_equal true, nested_selection.selected?
      assert_equal false, next_lookahead.selection(:similar_species).selection(:name).selected?
    end

    it "can detect fields on lists with symbol or string" do
      assert_equal true, query.lookahead.selection(:find_bird_species).selection(:similar_species).selection(:is_waterfowl).selected?
      assert_equal true, query.lookahead.selection("findBirdSpecies").selection("similarSpecies").selection("isWaterfowl").selected?
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
        merged_lookahead = query.lookahead.selection(:find_bird_species).selection(:similar_species)
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
      assert_equal [:find_bird_species], context[:root_lookahead_selections].map(&:name).uniq
      assert_equal(
        [{ by_name: "Cardinal" }, { by_name: "Scarlet Tanager" }, { by_name: "Great Blue Heron" }],
        context[:root_lookahead_selections].map(&:arguments)
      )
    end

    it "works for invalid queries" do
      context = {lookahead_latin_name: 0}
      res = LookaheadTest::Schema.execute("{ doesNotExist }", context: context)
      assert res.key?("errors")
      assert_equal 0, context[:lookahead_latin_name]
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
      GraphQL::Query.new(LookaheadTest::Schema, document: doc)
    end

    it "provides a list of all selections" do
      ast_node = document.definitions.first.selections.first
      field = LookaheadTest::Query.fields["findBirdSpecies"]
      lookahead = GraphQL::Execution::Lookahead.new(query: query, ast_nodes: [ast_node], field: field)
      assert_equal [:name, :similar_species], lookahead.selections.map(&:name)
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

    it 'handles duplicate selections across fragments' do
      doc = GraphQL.parse <<-GRAPHQL
        query {
          ... on Query {
            ...MoreFields
          }
        }

        fragment MoreFields on Query {
          findBirdSpecies(byName: "Laughing Gull") {
            name
          }
          findBirdSpecies(byName: "Laughing Gull") {
            ...EvenMoreFields
          }
        }

        fragment EvenMoreFields on BirdSpecies {
          similarSpecies {
            likesWater: isWaterfowl
          }
        }
      GRAPHQL

      lookahead = query(doc).lookahead

      root_selections = lookahead.selections
      assert_equal [:find_bird_species], root_selections.map(&:name), "Selections are merged"
      assert_equal 2, root_selections.first.ast_nodes.size, "It represents both nodes"

      assert_equal [:name, :similar_species], root_selections.first.selections.map(&:name), "Subselections are merged"
    end

    it "avoids merging selections for same field name on distinct types" do
      query = GraphQL::Query.new(LookaheadTest::Schema, <<-GRAPHQL)
        query {
          node(id: "Cardinal") {
            ... on BirdSpecies {
              name
            }
            ... on BirdGenus {
              name
            }
            id
          }
        }
      GRAPHQL

      node_lookahead = query.lookahead.selection("node")
      assert_equal(
        [[LookaheadTest::Node, :id], [LookaheadTest::BirdSpecies, :name], [LookaheadTest::BirdGenus, :name]],
        node_lookahead.selections.map { |s| [s.owner_type, s.name] }
      )
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

    it "excludes fields skipped by directives" do
      document = GraphQL.parse <<-GRAPHQL
        query($skipName: Boolean!, $includeGenus: Boolean!){
          findBirdSpecies(byName: "Cardinal") {
            id
            name @skip(if: $skipName)
            genus @include(if: $includeGenus)
          }
        }
      GRAPHQL
      query = GraphQL::Query.new(LookaheadTest::Schema, document: document,
        variables: { skipName: false, includeGenus: true })
      lookahead = query.lookahead.selection("findBirdSpecies")
      assert_equal [:id, :name, :genus], lookahead.selections.map(&:name)
      assert_equal true, lookahead.selects?(:name)

      query = GraphQL::Query.new(LookaheadTest::Schema, document: document,
        variables: { skipName: true, includeGenus: false })
      lookahead = query.lookahead.selection("findBirdSpecies")
      assert_equal [:id], lookahead.selections.map(&:name)
      assert_equal false, lookahead.selects?(:name)
    end
  end
end
