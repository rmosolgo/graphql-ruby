# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Partial do
  class PartialSchema < GraphQL::Schema
    module Database
      FARMS = {
        "1" => OpenStruct.new(name: "Bellair Farm", products: ["VEGETABLES", "MEAT", "EGGS"], neighboring_farm_id: "2"),
        "2" => OpenStruct.new(name: "Henley's Orchard", products: ["FRUIT", "MEAT", "EGGS"], neighboring_farm_id: "3"),
        "3" => OpenStruct.new(name: "Wenger Grapes", products: ["FRUIT"], neighboring_farm_id: "1"),
      }

      class << self
        def get(id)
          @log << [:get, id]
          FARMS[id]
        end

        def mget(ids)
          @log << [:mget, ids]
          ids.map { |id| FARMS[id] }
        end

        attr_reader :log

        def clear
          @log = []
        end
      end
    end

    class FarmSource < GraphQL::Dataloader::Source
      def fetch(farm_ids)
        Database.mget(farm_ids)
      end
    end

    class FarmProduct < GraphQL::Schema::Enum
      value :FRUIT
      value :VEGETABLES
      value :MEAT, value: :__MEAT__
      value :EGGS
      value :DAIRY
    end

    module Entity
      include GraphQL::Schema::Interface
      field :name, String
    end

    class Farm < GraphQL::Schema::Object
      implements Entity
      field :name, String
      field :products, [FarmProduct]
      field :error, Int

      def error
        raise GraphQL::ExecutionError, "This is a field error"
      end

      field :neighboring_farm, Farm

      def neighboring_farm
        dataloader.with(FarmSource).load(object.neighboring_farm_id)
      end
    end

    class UpcasedFarm < GraphQL::Schema::Object
      field :name, String

      def name
        object[:name].upcase
      end
    end

    class Market < GraphQL::Schema::Object
      implements Entity
      field :is_year_round, Boolean
    end

    class Thing < GraphQL::Schema::Union
      possible_types(Farm, Market)
    end

    class Query < GraphQL::Schema::Object
      field :farms, [Farm], fallback_value: Database::FARMS.values

      field :farm, Farm do
        argument :id, ID, loads: Farm, as: :farm
      end

      def farm(farm:)
        farm
      end

      field :farm_names, [String], fallback_value: Database::FARMS.each_value.map(&:name)

      field :query, Query, fallback_value: true

      field :thing, Thing

      def thing
        Database.get("1")
      end

      field :entity, Entity
      def entity; Database.get("1"); end

      field :read_context, String do
        argument :key, String
      end

      def read_context(key:)
        -> { context[key].to_s }
      end

      field :current_path, [String]
      def current_path
        context.current_path
      end

      field :current_values, [String]
      def current_values
        [
          GraphQL::Current.operation_name,
          GraphQL::Current.field.path,
          GraphQL::Current.dataloader_source_class.inspect,
        ]
      end
    end

    class Mutation < GraphQL::Schema::Object
      field :update_farm, Farm do
        argument :name, String
      end

      def update_farm(name:)
        { name: name }
      end
    end

    query(Query)
    mutation(Mutation)

    def self.object_from_id(id, ctx)
      ctx.dataloader.with(FarmSource).load(id)
    end

    def self.resolve_type(abs_type, object, ctx)
      object[:is_market] ? Market : Farm
    end

    use GraphQL::Dataloader
    lazy_resolve Proc, :call
  end

  before do
    PartialSchema::Database.clear
  end

  def run_partials(string, partial_configs, **query_kwargs)
    query = GraphQL::Query.new(PartialSchema, string, **query_kwargs)
    query.run_partials(partial_configs)
  end

  it "returns results for the named parts" do
    str = "{
      farms { name, products }
      farm1: farm(id: \"1\") { name }
      farm2: farm(id: \"2\") { name }
    }"
    results = run_partials(str, [
      { path: ["farm1"], object: PartialSchema::Database::FARMS["1"] },
      { path: ["farm2"], object: OpenStruct.new(name: "Injected Farm") },
      { path: ["farms", 0], object: { name: "Kestrel Hollow", products: [:__MEAT__, "EGGS"]} },
    ])

    assert_equal [
      { "data" => { "name" => "Bellair Farm" } },
      { "data" => { "name" => "Injected Farm" } },
      {"data" => {"name" => "Kestrel Hollow", "products" => ["MEAT", "EGGS"]} },
    ], results
  end

  it "runs inline fragments" do
    str = "{
      farm(id: \"1\") {
        ... on Farm {
          name
          ... {
            n2: name
          }
        }
      }
    }"

    document = GraphQL.parse(str)
    fragment_node = document.definitions.first.selections.first.selections.first
    other_fragment_node = fragment_node.selections[1]
    results = run_partials(str, [
      { fragment_node: fragment_node, type: PartialSchema::Farm, object: { name: "Belair Farm" } },
      { fragment_node: other_fragment_node, type: PartialSchema::UpcasedFarm, object: { name: "Free Union Grass Farm" } }
    ])
    assert_equal({ "name" => "Belair Farm", "n2" => "Belair Farm" }, results[0]["data"])
    assert_equal({ "n2" => "FREE UNION GRASS FARM" }, results[1]["data"])
  end

  it "runs fragment definitions" do
    str = "{
     farm(id: \"1\") { ... farmFields }
    }

    fragment farmFields on Farm {
      farmName: name
    }"

    node = GraphQL.parse(str).definitions.last
    results = run_partials(str, [{ fragment_node: node, type: PartialSchema::Farm, object: { name: "Clovertop Creamery" } }])
    assert_equal({ "farmName" => "Clovertop Creamery" }, results[0]["data"])
  end

  it "works with GraphQL::Current" do
    res = run_partials("query CheckCurrentValues { query { currentValues } }", [path: ["query"], object: nil])
    assert_equal ["CheckCurrentValues", "Query.currentValues", "nil"], res[0]["data"]["currentValues"]
  end

  it "returns errors if they occur" do
    str = "{
      farm1: farm(id: \"1\") { error }
      farm2: farm(id: \"1\") { name  }
      farm3: farm(id: \"1\") { name fieldError: error }
      farm4: farm(id: \"1\") {
        neighboringFarm {
          error
        }
      }
    }"
    results = run_partials(str, [
      { path: ["farm1"], object: PartialSchema::Database::FARMS["1"] },
      { path: ["farm2"], object: PartialSchema::Database::FARMS["2"] },
      { path: ["farm3"], object: PartialSchema::Database::FARMS["3"] },
      { path: ["farm4"], object: PartialSchema::Database::FARMS["3"] },
    ])


    assert_equal [{"message"=>"This is a field error", "locations"=>[{"line"=>2, "column"=>30}], "path"=>["farm1", "error"]}], results[0]["errors"]
    refute results[1].key?("errors")
    assert_equal [{"message"=>"This is a field error", "locations"=>[{"line"=>4, "column"=>35}], "path"=>["farm3", "fieldError"]}], results[2]["errors"]
    assert_equal [{"message"=>"This is a field error", "locations"=>[{"line"=>7, "column"=>11}], "path"=>["farm4", "neighboringFarm", "error"]}], results[3]["errors"]
    assert_equal({ "error" => nil }, results[0]["data"])
    assert_equal({ "name" => "Henley's Orchard" }, results[1]["data"])
    assert_equal({ "name" => "Wenger Grapes", "fieldError" => nil }, results[2]["data"])
    assert_equal({ "neighboringFarm" => { "error" => nil } }, results[3]["data"])
  end

  it "raises errors when given nonexistent paths" do
    str = "{ farm1: farm(id: \"1\") { error neighboringFarm { name } } }"
    query = GraphQL::Query.new(PartialSchema, str)
    err = assert_raises ArgumentError do
      query.run_partials([{ path: ["farm500"], object: PartialSchema::Database::FARMS["1"] }])
    end
    assert_equal "Path `[\"farm500\"]` is not present in this query. `\"farm500\"` was not found. Try a different path or rewrite the query to include it.", err.message

    err = assert_raises ArgumentError do
      query.run_partials([{ path: ["farm1", "neighboringFarm", "blah"], object: PartialSchema::Database::FARMS["1"] }])
    end
    assert_equal "Path `[\"farm1\", \"neighboringFarm\", \"blah\"]` is not present in this query. `\"blah\"` was not found. Try a different path or rewrite the query to include it.", err.message
  end

  it "can run partials with the same path" do
    str = "{
      farm(id: \"1\") { name }
    }"
    results = run_partials(str, [
      { path: ["farm"], object: PartialSchema::Database::FARMS["1"] },
      { path: ["farm"], object: -> { OpenStruct.new(name: "Injected Farm") } }
    ])

    assert_equal [
      { "data" => { "name" => "Bellair Farm" } },
      { "data" => { "name" => "Injected Farm" } },
    ], results
  end

  it "runs multiple partials concurrently" do
    str = <<~GRAPHQL
      query {
       query1: query { farm(id: "1") { name neighboringFarm { name } } }
       query2: query { farm(id: "2") { name neighboringFarm { name } } }
      }
    GRAPHQL

    results = run_partials(str, [{ path: ["query1"], object: true }, { path: ["query2"], object: true }])
    assert_equal "Henley's Orchard", results.first["data"]["farm"]["neighboringFarm"]["name"]
    assert_equal "Wenger Grapes", results.last["data"]["farm"]["neighboringFarm"]["name"]

    assert_equal [[:mget, ["1", "2"]], [:mget, ["3"]]], PartialSchema::Database.log
  end

  it "runs arrays and returns useful metadata in the result" do
    str = "{ farms { name } }"
    results = run_partials(str, [{ path: ["farms"], object: [{ name: "Twenty Paces" }, { name: "Spring Creek Blooms" }]}])
    result = results.first
    assert_equal [{ "name" => "Twenty Paces" }, { "name" => "Spring Creek Blooms" }], result["data"]
    assert_equal ["farms"], result.path
    assert_instance_of GraphQL::Query::Context, result.context
    assert_instance_of GraphQL::Query::Partial, result.partial
    assert_instance_of GraphQL::Query::Partial, result.context.query
    refute result.partial.leaf?
  end

  it "works on lists of scalars" do
    str = "{ query { farmNames } }"
    results = run_partials(str, [
      { path: ["query", "farmNames", 0], object: "Twenty Paces" },
      { path: ["query", "farmNames", 1], object: "Caromont" },
      { path: ["query", "farmNames", 2], object: GraphQL::ExecutionError.new("Boom!") },
    ])
    assert_equal "Twenty Paces", results[0]["data"]
    assert_equal "Caromont", results[1]["data"]
    assert_equal({
      "errors" => [{"message" => "Boom!", "locations" => [{"line" => 1, "column" => 11}], "path" => ["query", "farmNames", 2, "farmNames"]}],
      "data" => nil
    }, results[2])
  end

  it "merges selections when path steps are duplicated" do
    str = <<-GRAPHQL
      {
        farm(id: 5) { neighboringFarm { name } }
        farm(id: 5) { neighboringFarm { name2: name } }
      }
    GRAPHQL
    results = run_partials(str, [{ path: ["farm", "neighboringFarm"], object: OpenStruct.new(name: "Dawnbreak") }])

    assert_equal({"name" => "Dawnbreak", "name2" => "Dawnbreak" }, results.first["data"])
  end

  it "works when there are inline fragments in the path" do
    str = <<-GRAPHQL
      {
        farm(id: "BLAH") {
          ... on Farm {
            neighboringFarm {
              name
            }
          }
          neighboringFarm {
            __typename
          }
          ...FarmFields
        }
      }

      fragment FarmFields on Farm {
        neighboringFarm {
          n2: name
        }
      }
    GRAPHQL

    results = run_partials(str, [{ path: ["farm", "neighboringFarm"], object: OpenStruct.new(name: "Dawnbreak") }])
    assert_equal({"name" => "Dawnbreak", "__typename" => "Farm", "n2" => "Dawnbreak"}, results.first["data"])
  end

  it "runs partials on scalars and enums" do
    str = "{ farm(id: \"BLAH\") { name products } }"
    results = run_partials(str, [
      { path: ["farm", "name"], object: "Polyface" },
      { path: ["farm", "products"], object: [:__MEAT__] },
      { path: ["farm", "products"], object: -> { ["EGGS"] } },
    ])
    assert_equal ["Polyface", ["MEAT"], ["EGGS"]], results.map { |r| r["data"] }

    assert results[0].partial.leaf?
    assert results[1].partial.leaf?
    assert results[2].partial.leaf?
  end


  it "runs on union selections" do
    str = "{
      thing {
        ...on Farm { name }
        ...on Market { name isYearRound }
      }
    }"

    results = run_partials(str, [
      { path: ["thing"], object: { name: "Whisper Hill" } },
      { path: ["thing"], object: { is_market: true, name: "Crozet Farmers Market", is_year_round: false } },
    ])

    assert_equal({ "name" => "Whisper Hill" }, results[0]["data"])
    assert_equal({ "name" => "Crozet Farmers Market", "isYearRound" => false }, results[1]["data"])
  end

  it "runs on interface selections" do
    str = "{
      entity {
        name
        __typename
      }
    }"

    results = run_partials(str, [
      { path: ["entity"], object: { name: "Whisper Hill" } },
      { path: ["entity"], object: { is_market: true, name: "Crozet Farmers Market" } },
    ])

    assert_equal({ "name" => "Whisper Hill", "__typename" => "Farm" }, results[0]["data"])
    assert_equal({ "name" => "Crozet Farmers Market", "__typename" => "Market" }, results[1]["data"])
  end

  it "runs scalars on abstract types" do
    str = "{
      entity {
        name
        __typename
      }
    }"

    results = run_partials(str, [
      { path: ["entity", "name"], object: "Whisper Hill" },
      { path: ["entity", "__typename"], object: "Farm" },
      { path: ["entity", "name"], object: "Crozet Farmers Market" },
    ])

    assert_equal("Whisper Hill", results[0]["data"])
    assert_equal("Farm", results[1]["data"])
    assert_equal("Crozet Farmers Market", results[2]["data"])
  end

  it "accepts custom context" do
    str = "{ readContext(key: \"custom\") }"
    results = run_partials(str, [
      { path: [], object: nil, context: { "custom" => "one" } },
      { path: [], object: nil, context: { "custom" => "two" } },
      { path: [], object: nil },
    ], context: { "custom" => "three"} )
    assert_equal "one", results[0]["data"]["readContext"]
    assert_equal "two", results[1]["data"]["readContext"]
    assert_equal "three", results[2]["data"]["readContext"]
  end

  it "uses a full path relative to the parent query" do
    str = "{ q1: query { q2: query { query { currentPath } } } }"
    results = run_partials(str, [
      { path: [], object: nil },
      { path: ["q1", "q2"], object: nil },
      { path: ["q1", "q2", "query"], object: nil },
      { path: ["q1", "q2", "query", "currentPath"], object: ["injected", "path"] },
    ])

    assert_equal({"q1" => { "q2" => { "query" => { "currentPath" => ["q1", "q2", "query", "currentPath"] } } } }, results[0]["data"])
    assert_equal [], results[0].partial.path
    assert_equal({"query" => {"currentPath" => ["q1", "q2", "query", "currentPath"]}}, results[1]["data"])
    assert_equal ["q1", "q2"], results[1].partial.path
    assert_equal({ "currentPath" => ["q1", "q2", "query", "currentPath"] }, results[2]["data"])
    assert_equal ["q1", "q2", "query"], results[2].partial.path
    assert_equal(["injected", "path"], results[3]["data"])
    assert_equal ["q1", "q2", "query", "currentPath"], results[3].partial.path
  end

  it "runs partials on mutation root" do
    str = "mutation { updateFarm(name: \"Brawndo Acres\") { name } }"
    results = run_partials(str, [
      { path: [], object: nil },
      { path: ["updateFarm"], object: { name: "Georgetown Farm" } },
      { path: ["updateFarm", "name"], object: "Notta Farm" },
    ])

    assert_equal({ "updateFarm" => { "name" => "Brawndo Acres" } }, results[0]["data"])
    assert_equal({ "name" => "Georgetown Farm" }, results[1]["data"])
    assert_equal("Notta Farm", results[2]["data"])
  end

  it "handles errors on scalars" do
    str = "{
      entity {
        name
        __typename
      }
    }"

    results = run_partials(str, [
      { path: ["entity"], object: { name: GraphQL::ExecutionError.new("Boom!") } },
      { path: ["entity", "name"], object: GraphQL::ExecutionError.new("Bang!") },
      { path: ["entity", "name"], object: -> { GraphQL::ExecutionError.new("Blorp!") } },
    ])

    assert_equal({
      "errors" => [{"message" => "Boom!", "locations" => [{"line" => 3, "column" => 9}], "path" => ["entity", "name"]}],
      "data" => { "name" => nil, "__typename" => "Farm" }
    }, results[0])
    assert_equal({
      "errors" => [{"message" => "Bang!", "locations" => [{"line" => 3, "column" => 9}], "path" => ["entity", "name", "name"]}],
      "data" => nil
    }, results[1])
    assert_equal({
      "errors" => [{"message" => "Blorp!", "locations" => [{"line" => 3, "column" => 9}], "path" => ["entity", "name", "name"]}],
      "data" => nil
    }, results[2])
  end
end
