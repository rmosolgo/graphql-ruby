# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Visibility::Subset do
  class SubsetSchema < GraphQL::Schema
    class Thing < GraphQL::Schema::Object
      field :name, String, method: :to_s
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing, fallback_value: :Something
      field :greeting, String
    end

    query(Query)

    use GraphQL::Schema::Visibility
  end
  it "only loads the types it needs" do
    query = GraphQL::Query.new(SubsetSchema, "{ thing { name } }", use_schema_subset: true)
    assert_equal [], query.types.loaded_types
    res = query.result

    assert_equal "Something", res["data"]["thing"]["name"]
    assert_equal ["Query", "String", "Thing"], query.types.loaded_types.map(&:graphql_name).sort
  end
end
