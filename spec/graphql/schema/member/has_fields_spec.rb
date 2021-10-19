# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasFields do
  class MultifieldSchema < GraphQL::Schema
    module AppliesToFutureSchema
      def initialize(*args, future_schema: nil, **kwargs, &block)
        @future_schema = future_schema
        super(*args, **kwargs, &block)
      end

      def applies?(context)
        @future_schema.nil? || @future_schema == context[:future_schema]
      end

      attr_accessor :future_schema
    end

    class BaseArgument < GraphQL::Schema::Argument
      include AppliesToFutureSchema
    end

    class BaseField < GraphQL::Schema::Field
      include AppliesToFutureSchema
      argument_class BaseArgument
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
      extend AppliesToFutureSchema
    end

    module BaseInterface
      include GraphQL::Schema::Interface
      field_class BaseField
    end

    class BaseScalar < GraphQL::Schema::Scalar
      extend AppliesToFutureSchema
    end

    module Node
      include BaseInterface

      field :id, Int, null: false, future_schema: true, deprecation_reason: "Use databaseId instead"
      field :id, Int, null: false

      field :database_id, Int, null: false, future_schema: true
      field :uuid, ID, null: false, future_schema: true
    end

    class MoneyScalar < BaseScalar
      graphql_name "Money"
    end

    class LegacyMoney < MoneyScalar
      graphql_name "LegacyMoney"
    end

    class Money < BaseObject
      field :amount, Integer, null: false
      field :currency, String, null: false

      self.future_schema = true
    end

    class LegacyThing < BaseObject
      implements Node
      field :price, LegacyMoney, null: true
    end

    class Thing < LegacyThing
      field :price, Money, null: true, future_schema: true
      field :price, MoneyScalar, null: true, method: :legacy_price
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
        # TODO: here's a place where priority matters in the source.
        # If these arguments are reordered, a test below fails
        # because the "legacy" argument passes .applies? first.
        # Consider making the code assert that only one among the
        # possible definitions passes.
        argument :id, ID, required: true, future_schema: true
        argument :id, Int, required: true
      end

      def thing(id:)
        { id: id, database_id: id, uuid: "thing-#{id}", legacy_price: "⚛︎#{id}00", price: { amount: id.to_i * 100, currency: "⚛︎" }}
      end

      field :legacy_thing, LegacyThing, null: false do
        argument :id, ID, required: true
      end

      def legacy_thing(id:)
        { id: id, database_id: id, uuid: "thing-#{id}", price: "⚛︎#{id}00" }
      end
    end

    class BaseMutation < GraphQL::Schema::RelayClassicMutation
      argument_class BaseArgument
      field_class BaseField
    end

    class UpdateThing < BaseMutation
      argument :thing_id, ID, required: true, future_schema: true
      argument :thing_id, Int, required: true
      argument :price, Int, required: true

      field :thing, Thing, null: false
      def resolve(thing_id:, price:)
        {
          thing: { id: thing_id, uuid: thing_id, legacy_price: "£#{price}", price: { amount: price, currency: "£"} }
        }
      end
    end

    class Mutation < BaseObject
      field :update_thing, mutation: UpdateThing
    end

    query(Query)
    mutation(Mutation)
  end

  def exec_query(*args, **kwargs)
    MultifieldSchema.execute(*args, **kwargs)
  end

  def exec_future_query(*args, **kwargs)
    context = kwargs[:context] ||= {}
    context[:future_schema] = true
    exec_query(*args, **kwargs)
  end

  it "returns different fields according context for Ruby methods, runtime, introspection, and to_definition" do
    # Accessing in Ruby
    assert_equal GraphQL::Types::Int, MultifieldSchema::Query.get_field("f1").type
    assert_equal GraphQL::Types::String, MultifieldSchema::Query.get_field("f1", { future_schema: true }).type

    # GraphQL usage
    query_str = "{ f1 }"
    assert_equal 123, exec_query(query_str)["data"]["f1"]
    assert_equal "abcdef", exec_future_query(query_str)["data"]["f1"]

    # GraphQL Introspection
    introspection_query_str = '{ __type(name: "Query") { fields { type { name } } } }'
    assert_equal "Int", exec_query(introspection_query_str)["data"]["__type"]["fields"].first["type"]["name"]
    assert_equal "String", exec_future_query(introspection_query_str)["data"]["__type"]["fields"].first["type"]["name"]

    # Schema dump
    assert_includes MultifieldSchema.to_definition, <<-GRAPHQL
type Query {
  f1: Int
  legacyThing(id: ID!): LegacyThing!
  thing(id: Int!): Thing
}
GRAPHQL

    assert_includes MultifieldSchema.to_definition(context: { future_schema: true }), <<-GRAPHQL
type Query {
  f1: String
  legacyThing(id: ID!): LegacyThing!
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
    exec_query(query_str)["errors"].map { |e| e["message"] }
    res = exec_future_query(query_str)
    assert_equal({ "thing" => { "databaseId" => 15, "id" => 15, "uuid" => "thing-15"} }, res["data"])
  end

  it "supports different versions of field arguments" do
    res = exec_future_query("{ thing(id: \"15\") { id } }")
    assert_equal 15, res["data"]["thing"]["id"]
    # On legacy, `"15"` is parsed as an int, which makes it null:
    res = exec_query("{ thing(id: \"15\") { id } }")
    assert_equal ["Argument 'id' on Field 'thing' has an invalid value (\"15\"). Expected type 'Int!'."], res["errors"].map { |e| e["message"] }

    introspection_query = "{ __type(name: \"Query\") { fields { name args { name type { name ofType { name } } } } } }"
    introspection_res = exec_query(introspection_query)
    assert_equal "Int", introspection_res["data"]["__type"]["fields"].find { |f| f["name"] == "thing" }["args"].first["type"]["ofType"]["name"]

    introspection_res = exec_future_query(introspection_query)
    assert_equal "ID", introspection_res["data"]["__type"]["fields"].find { |f| f["name"] == "thing" }["args"].first["type"]["ofType"]["name"]
  end

  it "supports different versions of input object arguments" do
    res = exec_query("mutation { updateThing(input: { thingId: 12, price: 100 }) { thing { price id } } }")
    assert_equal "£100", res["data"]["updateThing"]["thing"]["price"]
    assert_equal 12, res["data"]["updateThing"]["thing"]["id"]

    res = exec_future_query("mutation { updateThing(input: { thingId: \"11\", price: 120 }) { thing { uuid price { amount } } } }")
    assert_equal "11", res["data"]["updateThing"]["thing"]["uuid"]
    assert_equal 120, res["data"]["updateThing"]["thing"]["price"]["amount"]

    introspection_query_str = "{ __type(name: \"UpdateThingInput\") { inputFields { name type { name ofType { name } } } } }"
    res = exec_query(introspection_query_str)
    assert_equal "Int", res["data"]["__type"]["inputFields"].find { |f| f["name"] == "thingId" }["type"]["ofType"]["name"]
    res = exec_future_query(introspection_query_str)
    assert_equal "ID", res["data"]["__type"]["inputFields"].find { |f| f["name"] == "thingId" }["type"]["ofType"]["name"]
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

    assert_equal MultifieldSchema::MoneyScalar, MultifieldSchema.get_type("Money")
    assert_equal MultifieldSchema::Money, MultifieldSchema.get_type("Money", { future_schema: true })

    assert_equal "⚛︎100",exec_query("{ thing(id: 1) { price } }")["data"]["thing"]["price"]
    res = exec_query("{ __type(name: \"Money\") { kind name } }")
    assert_equal "SCALAR", res["data"]["__type"]["kind"]
    assert_equal "Money", res["data"]["__type"]["name"]
    assert_equal({ "amount" => 200, "currency" => "⚛︎" }, exec_future_query("{ thing(id: 2) { price { amount currency } } }")["data"]["thing"]["price"])
    res = exec_future_query("{ __type(name: \"Money\") { name kind } }")
    assert_equal "OBJECT", res["data"]["__type"]["kind"]
    assert_equal "Money", res["data"]["__type"]["name"]
  end

  it "works with subclasses" do
    res = exec_query("{ legacyThing(id: 1) { price } thing(id: 3) { price } }")
    assert_equal "⚛︎100", res["data"]["legacyThing"]["price"]
    assert_equal "⚛︎300", res["data"]["thing"]["price"]

    future_res = exec_future_query("{ legacyThing(id: 1) { price } thing(id: 3) { price { amount } } }")
    assert_equal "⚛︎100", future_res["data"]["legacyThing"]["price"]
    assert_equal 300, future_res["data"]["thing"]["price"]["amount"]
  end
end
