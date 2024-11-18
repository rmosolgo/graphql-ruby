# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Visibility::Profile do
  class ProfileSchema < GraphQL::Schema
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
    query = GraphQL::Query.new(ProfileSchema, "{ thing { name } }", use_visibility_profile: true)
    assert_equal [], query.types.loaded_types

    res = query.result
    assert_equal "Something", res["data"]["thing"]["name"]
    assert_equal [], query.types.loaded_types.map(&:graphql_name).sort

    query = GraphQL::Query.new(ProfileSchema, "{ __schema { types { name }} }", use_visibility_profile: true)
    assert_equal [], query.types.loaded_types

    res = query.result
    assert_equal 12, res["data"]["__schema"]["types"].size
    loaded_type_names = query.types.loaded_types.map(&:graphql_name).reject { |n| n.start_with?("__") }.sort
    assert_equal ["Boolean", "Query", "String", "Thing"], loaded_type_names
  end
end
