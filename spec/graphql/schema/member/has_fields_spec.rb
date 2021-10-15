# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasFields do
  class MultifieldSchema < GraphQL::Schema
    class BaseField < GraphQL::Schema::Field
      def initialize(*args, future_schema: nil, **kwargs, &block)
        @future_schema = future_schema
        super(*args, **kwargs, &block)
      end

      def applies?(context)
        @future_schema.nil? || @future_schema == context[:future_schema]
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField

      class << self
        attr_writer :future_schema
      end

      def self.applies?(context)
        @future_schema == context[:future_schema]
      end
    end

    module BaseInterface
      include GraphQL::Schema::Interface
      field_class BaseField
    end

    class BaseScalar < GraphQL::Schema::Scalar
      class << self
        attr_writer :future_schema
      end

      def self.applies?(context)
        @future_schema == context[:future_schema]
      end
    end

    module Node
      include BaseInterface

      field :id, Int, null: false, future_schema: true, deprecation_reason: "Use databaseId instead"
      field :id, Int, null: false

      field :database_id, Int, null: false, future_schema: true
      field :uuid, ID, null: false, future_schema: true
    end

    class LegacyMoney < BaseScalar
      graphql_name "Money"
    end

    class Money < BaseObject
      field :amount, Integer, null: false
      field :currency, String, null: false

      self.future_schema = true
    end

    class Thing < BaseObject
      implements Node

      field :price, Money, null: true, future_schema: true
      field :price, LegacyMoney, null: true, method: :legacy_price
    end

    class Query < BaseObject
      field :f1, String, null: true, future_schema: true
      field :f1, Int, null: true

      def f1
        if context[:future_schema]
          "abcdef"
        else
          123
        end
      end

      field :thing, Thing, null: true do
        argument :id, ID, required: true
      end

      def thing(id:)
        { id: id, database_id: id, uuid: "thing-#{id}", legacy_price: "⚛︎100", price: { amount: 100, currency: "⚛︎" }}
      end
    end

    query(Query)
  end

  it "returns different fields according context for Ruby methods, runtime, introspection, and to_definition" do
    # Accessing in Ruby
    assert_equal GraphQL::Types::Int, MultifieldSchema::Query.get_field("f1").type
    assert_equal GraphQL::Types::String, MultifieldSchema::Query.get_field("f1", { future_schema: true }).type

    # GraphQL usage
    query_str = "{ f1 }"
    assert_equal 123, MultifieldSchema.execute(query_str)["data"]["f1"]
    assert_equal "abcdef", MultifieldSchema.execute(query_str, context: { future_schema: true })["data"]["f1"]

    # GraphQL Introspection
    introspection_query_str = '{ __type(name: "Query") { fields { type { name } } } }'
    assert_equal "Int", MultifieldSchema.execute(introspection_query_str)["data"]["__type"]["fields"].first["type"]["name"]
    assert_equal "String", MultifieldSchema.execute(introspection_query_str, context: { future_schema: true })["data"]["__type"]["fields"].first["type"]["name"]

    # Schema dump
    assert_includes MultifieldSchema.to_definition, <<-GRAPHQL
type Query {
  f1: Int
  thing(id: ID!): Thing
}
GRAPHQL

    assert_includes MultifieldSchema.to_definition(context: { future_schema: true }), <<-GRAPHQL
type Query {
  f1: String
  thing(id: ID!): Thing
}
GRAPHQL
  end

  it "serves interface fields according to the per-query version" do
    # Schema dump
    assert_includes MultifieldSchema.to_definition, <<-GRAPHQL
interface Node {
  id: Int!
}
GRAPHQL

    assert_includes MultifieldSchema.to_definition(context: { future_schema: true }), <<-GRAPHQL
interface Node {
  databaseId: Int!
  id: Int! @deprecated(reason: "Use databaseId instead")
  uuid: ID!
}
GRAPHQL

    query_str = "{ thing(id: 15) { databaseId id uuid } }"
    assert_equal ["Field 'databaseId' doesn't exist on type 'Thing'", "Field 'uuid' doesn't exist on type 'Thing'"],
      MultifieldSchema.execute(query_str)["errors"].map { |e| e["message"] }
    res = MultifieldSchema.execute(query_str, context: { future_schema: true })
    assert_equal({ "thing" => { "databaseId" => 15, "id" => 15, "uuid" => "thing-15"} }, res["data"])
  end

  it "can migrate scalars to objects" do
    # Schema dump
    assert_includes MultifieldSchema.to_definition, "scalar Money"
    refute_includes MultifieldSchema.to_definition, "type Money"

    assert_includes MultifieldSchema.to_definition(context: { future_schema: true }), <<-GRAPHQL
type Money {
  amount: Int!
  currency: String!
}
GRAPHQL
    refute_includes MultifieldSchema.to_definition(context: { future_schema: true }), "scalar Money"


    assert_equal MultifieldSchema::LegacyMoney, MultifieldSchema.get_type("Money")
    assert_equal MultifieldSchema::Money, MultifieldSchema.get_type("Money", { future_schema: true })

    assert_equal "⚛︎100", MultifieldSchema.execute("{ thing(id: 1) { price } }")["data"]["thing"]["price"]
    res = MultifieldSchema.execute("{ __type(name: \"Money\") { kind name } }")
    assert_equal "SCALAR", res["data"]["__type"]["kind"]
    assert_equal "Money", res["data"]["__type"]["name"]
    assert_equal({ "amount" => 100, "currency" => "⚛︎" }, MultifieldSchema.execute("{ thing(id: 1) { price { amount currency } } }", context: { future_schema: true })["data"]["thing"]["price"])
    res = MultifieldSchema.execute("{ __type(name: \"Money\") { name kind } }", context: { future_schema: true })
    assert_equal "OBJECT", res["data"]["__type"]["kind"]
    assert_equal "Money", res["data"]["__type"]["name"]
  end
end
