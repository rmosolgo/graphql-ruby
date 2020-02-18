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
    query_type =  GraphQL::ObjectType.define do
      name "DeepQuery"
       field :foo do
         type !GraphQL::ListType.new(
           of_type: !GraphQL::ListType.new(
             of_type: !GraphQL::ListType.new(
               of_type: GraphQL::FLOAT_TYPE
             )
           )
         )
       end
    end

     deep_schema = GraphQL::Schema.define do
       query query_type
     end

     result = deep_schema.execute(query_string)
     assert(GraphQL::Schema::Loader.load(result))
  end

  it "doesn't handle too deeply nested (< 8) schemas" do
    query_type =  GraphQL::ObjectType.define do
      name "DeepQuery"
       field :foo do
         type !GraphQL::ListType.new(
           of_type: !GraphQL::ListType.new(
             of_type: !GraphQL::ListType.new(
               of_type: !GraphQL::ListType.new(
                 of_type: GraphQL::FLOAT_TYPE
               )
             )
           )
         )
       end
    end

     deep_schema = GraphQL::Schema.define do
       query query_type
     end

     result = deep_schema.execute(query_string)
     assert_raises(KeyError) {
       GraphQL::Schema::Loader.load(result)
     }
  end
end
