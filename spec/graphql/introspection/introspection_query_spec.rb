# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Introspection::INTROSPECTION_QUERY" do
  let(:schema)  {
    Class.new(Dummy::Schema) do
      max_depth(15)
    end
  }
  let(:query_string) { GraphQL::Introspection::INTROSPECTION_QUERY }
  let(:result) { schema.execute(query_string) }

  it "runs" do
    assert(result["data"])
  end

  it "is limited to the max query depth" do
    query_type =  Class.new(GraphQL::Schema::Object) do
      graphql_name "DeepQuery"

      field :foo, [[[Float]]], null: false
    end

     deep_schema = Class.new(GraphQL::Schema) do
       query query_type
     end

     result = deep_schema.execute(query_string)
     assert(GraphQL::Schema::Loader.load(result))
  end

  it "doesn't handle too deeply nested (< 8) schemas" do
    query_type =  Class.new(GraphQL::Schema::Object) do
      graphql_name "DeepQuery"

      field :foo, [[[[Float]]]], null: false
    end

    deep_schema = Class.new(GraphQL::Schema) do
      query query_type
    end

     result = deep_schema.execute(query_string)
     assert_raises(KeyError) {
       GraphQL::Schema::Loader.load(result)
     }
  end
end
