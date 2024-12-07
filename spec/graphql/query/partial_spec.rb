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
      value :MEAT
      value :EGGS
      value :DAIRY
    end

    class Farm < GraphQL::Schema::Object
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

    class Query < GraphQL::Schema::Object
      field :farms, [Farm], fallback_value: Database::FARMS.values

      field :farm, Farm do
        argument :id, ID, loads: Farm, as: :farm
      end

      def farm(farm:)
        farm
      end

      field :query, Query, fallback_value: true
    end

    query(Query)

    def self.object_from_id(id, ctx)
      ctx.dataloader.with(FarmSource).load(id)
    end

    def self.resolve_type(abs_type, object, ctx)
      Farm
    end

    use GraphQL::Dataloader
  end

  before do
    PartialSchema::Database.clear
  end

  it "returns results for the named parts" do
    str = "{
      farms { name, products }
      farm1: farm(id: \"1\") { name }
      farm2: farm(id: \"2\") { name }
    }"
    query = GraphQL::Query.new(PartialSchema, str)
    results = query.run_partials([
      { path: ["farm1"], object: PartialSchema::Database::FARMS["1"] },
      { path: ["farm2"], object: OpenStruct.new(name: "Injected Farm") }
    ])

    assert_equal [
      { "data" => { "name" => "Bellair Farm" } },
      { "data" => { "name" => "Injected Farm" } },
    ], results
  end

  it "returns errors if they occur" do
    str = "{ farm1: farm(id: \"1\") { error } }"
    query = GraphQL::Query.new(PartialSchema, str)
    results = query.run_partials([{ path: ["farm1"], object: PartialSchema::Database::FARMS["1"] }])
    assert_nil results.first.fetch("data").fetch("error")
    assert_equal [["This is a field error"]], results.map { |r| r["errors"].map { |err| err["message"] } }
    assert_equal [[["error"]]], results.map { |r| r["errors"].map { |err| err["path"] } }
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
    query = GraphQL::Query.new(PartialSchema, str)
    results = query.run_partials([
      { path: ["farm"], object: PartialSchema::Database::FARMS["1"] },
      { path: ["farm"], object: OpenStruct.new(name: "Injected Farm") }
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

    query = GraphQL::Query.new(PartialSchema, str)
    results = query.run_partials([{ path: ["query1"], object: true }, { path: ["query2"], object: true }])

    assert_equal "Henley's Orchard", results.first["data"]["farm"]["neighboringFarm"]["name"]
    assert_equal "Wenger Grapes", results.last["data"]["farm"]["neighboringFarm"]["name"]

    assert_equal [[:mget, ["1", "2"]], [:mget, ["3"]]], PartialSchema::Database.log
  end

  it "returns multiple errors concurrently"

  it "runs arrays and returns useful metadata in the result" do
    str = "{ farms { name } }"
    query = GraphQL::Query.new(PartialSchema, str)
    results = query.run_partials([{ path: ["farms"], object: [{ name: "Twenty Paces" }, { name: "Spring Creek Blooms" }]}])
    result = results.first
    assert_equal [{ "name" => "Twenty Paces" }, { "name" => "Spring Creek Blooms" }], result["data"]
    assert_equal ["farms"], result.path
    assert_instance_of GraphQL::Query::Context, result.context
    refute_equal query.context, result.context
  end
end
