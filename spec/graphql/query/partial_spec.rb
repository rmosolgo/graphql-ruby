# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Partial do
  class PartialSchema < GraphQL::Schema
    FARMS = {
      "1" => OpenStruct.new(name: "Bellair Farm", products: ["VEGETABLES", "MEAT", "EGGS"]),
      "2" => OpenStruct.new(name: "Henley's Orchard", products: ["FRUIT", "MEAT", "EGGS"]),
      "3" => OpenStruct.new(name: "Wenger Grapes", products: ["FRUIT"]),
    }

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
    end

    class Query < GraphQL::Schema::Object
      field :farms, [Farm], fallback_value: FARMS.values

      field :farm, Farm do
        argument :id, ID, loads: Farm, as: :farm
      end

      def farm(farm:)
        farm
      end
    end

    query(Query)

    def self.object_from_id(id, ctx)
      FARMS[id]
    end

    def self.resolve_type(abs_type, object, ctx)
      Farm
    end
  end

  focus
  it "returns results for the named part" do
    str = "{
      farms { name, products }
      farm1: farm(id: \"1\") { name }
      farm2: farm(id: \"2\") { name }
    }"
    query = GraphQL::Query.new(PartialSchema, str)
    results = query.run_partials(
      ["farm1"] => PartialSchema::FARMS["1"],
      ["farm2"] => OpenStruct.new(name: "Injected Farm"),
    )

    assert_equal [
      { "data" => { "name" => "Bellair Farm" } },
      { "data" => { "name" => "Injected Farm" } },
    ], results
  end

  it "returns errors if they occur"
  it "raises errors when given bad paths"
  it "runs multiple partials concurrently"
  it "returns multiple errors concurrently"
end
