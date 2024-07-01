# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Shape do
  class ShapeSchema < GraphQL::Schema
    class Thing < GraphQL::Schema::Object
      field :name, String
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing, fallback_value: :Something
      field :greeting, String
    end

    query(Query)
  end
  it "only loads the types it needs" do
    query = GraphQL::Query.new(ShapeSchema, "{ thing { name } }", shape: true)
    assert_equal [], query.types.to_a
    res = query.result

    assert_equal "Something", res["data"]["thing"]["name"]
    assert_equal ["Query", "Thing", "String"], query.types.all_types.map(&:graphql_name)
  end
end
