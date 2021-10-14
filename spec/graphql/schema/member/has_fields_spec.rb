# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasFields do
  class MultifieldSchema < GraphQL::Schema
    class BaseField < GraphQL::Schema::Field
      def initialize(*args, applies_if: nil, **kwargs, &block)
        @applies_if = applies_if
        super(*args, **kwargs, &block)
      end

      def applies?(context)
        @applies_if.nil? || context[@applies_if]
      end
    end

    class Query < GraphQL::Schema::Object
      field_class BaseField
      field :f1, String, null: true, applies_if: :future_schema
      field :f1, Int, null: true

      def f1
        if context[:future_schema]
          "abcdef"
        else
          123
        end
      end
    end

    query(Query)
  end

  it "returns different fields according context for Ruby methods, runtime, introspection, and to_definition" do
    # Accessing in Ruby
    assert_equal [GraphQL::Types::Int], MultifieldSchema::Query.fields.values.map(&:type)
    assert_equal [GraphQL::Types::String], MultifieldSchema::Query.fields({ future_schema: true }).values.map(&:type)

    # GraphQL usage
    query_str = "{ f1 }"
    assert_equal 123, MultifieldSchema.execute(query_str)["data"]["f1"]
    assert_equal "abcdef", MultifieldSchema.execute(query_str, context: { future_schema: true })["data"]["f1"]

    # GraphQL Introspection
    introspection_query_str = '{ __type(name: "Query") { fields { type { name } } } }'
    assert_equal "Int", MultifieldSchema.execute(introspection_query_str)["data"]["__type"]["fields"].first["type"]["name"]
    assert_equal "String", MultifieldSchema.execute(introspection_query_str, context: { future_schema: true })["data"]["__type"]["fields"].first["type"]["name"]

    # Schema dump
    assert_equal <<-GRAPHQL, MultifieldSchema.to_definition
type Query {
  f1: Int
}
GRAPHQL

assert_equal <<-GRAPHQL, MultifieldSchema.to_definition(context: { future_schema: true })
type Query {
  f1: String
}
GRAPHQL
  end
end
