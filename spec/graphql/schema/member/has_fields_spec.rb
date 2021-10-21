# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasFields do
  class MultifieldSchema < GraphQL::Schema
    module AppliesToFutureSchema
      def initialize(*args, future_schema: nil, **kwargs, &block)
        @future_schema = future_schema
        super(*args, **kwargs, &block)
      end

      def visible?(context)
        @future_schema.nil? || (@future_schema == !!context[:future_schema])
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

    class BaseEnumValue < GraphQL::Schema::EnumValue
      include AppliesToFutureSchema
    end

    class BaseEnum < GraphQL::Schema::Enum
      enum_value_class BaseEnumValue
    end

    class Language < BaseEnum
      value "RUBY"
      value "PERL6", deprecation_reason: "Use RAKU instead", future_schema: true
      value "PERL6"
      value "RAKU", future_schema: true
      value "COFFEE_SCRIPT", future_schema: false
    end

    class Place < BaseObject
      implements Node
      self.future_schema = true
      field :future_place_field, String, null: true
    end

    class LegacyPlace < BaseObject
      implements Node
      graphql_name "Place"
      self.future_schema = false

      field :legacy_place_field, String, null: true
    end

    class BaseResolver < GraphQL::Schema::Resolver
      argument_class BaseArgument
    end

    class Add < BaseResolver
      argument :left, Float, required: true, future_schema: true
      argument :left, Int, required: true
      argument :right, Float, required: true, future_schema: true
      argument :right, Int, required: true

      type String, null: false

      def resolve(left:, right:)
        "#{left + right}"
      end
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

      field :favorite_language, Language, null: false do
        argument :lang, Language, required: false
      end

      def favorite_language(lang: nil)
        lang || context[:favorite_language] || "RUBY"
      end

      field :add, resolver: Add
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
    orphan_types(Place, LegacyPlace)
  end

  def exec_query(*args, **kwargs)
    MultifieldSchema.execute(*args, **kwargs)
  end

  def exec_future_query(*args, **kwargs)
    context = kwargs[:context] ||= {}
    context[:future_schema] = true
    exec_query(*args, **kwargs)
  end

  def future_schema_sdl
    MultifieldSchema.to_definition(context: { future_schema: true })
  end

  def legacy_schema_sdl
    MultifieldSchema.to_definition
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
    introspection_query_str = '{ __type(name: "Query") { fields { name type { name } } } }'
    assert_equal "Int", exec_query(introspection_query_str)["data"]["__type"]["fields"].find { |f| f["name"] == "f1" }["type"]["name"]
    assert_equal "String", exec_future_query(introspection_query_str)["data"]["__type"]["fields"].find { |f| f["name"] == "f1" }["type"]["name"]

    # Schema dump
    assert_includes legacy_schema_sdl, <<-GRAPHQL
type Query {
  add(left: Int!, right: Int!): String!
  f1: Int
  favoriteLanguage(lang: Language): Language!
  legacyThing(id: ID!): LegacyThing!
  thing(id: Int!): Thing
}
GRAPHQL

    assert_includes future_schema_sdl, <<-GRAPHQL
type Query {
  add(left: Float!, right: Float!): String!
  f1: String
  favoriteLanguage(lang: Language): Language!
  legacyThing(id: ID!): LegacyThing!
  thing(id: ID!): Thing
}
GRAPHQL
  end

  it "serves interface fields according to the per-query version" do
    # Schema dump
    assert_includes legacy_schema_sdl, <<-GRAPHQL
interface Node {
  id: Int!
}
GRAPHQL

    assert_includes future_schema_sdl, <<-GRAPHQL
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
    assert_includes legacy_schema_sdl, "scalar Money"
    refute_includes legacy_schema_sdl, "type Money"

    assert_includes future_schema_sdl, <<-GRAPHQL
type Money {
  amount: Int!
  currency: String!
}
GRAPHQL
    refute_includes future_schema_sdl, "scalar Money"

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


  it "supports different enum value definitions" do
    # Schema dump:
    legacy_schema = legacy_schema_sdl
    assert_includes legacy_schema, "COFFEE_SCRIPT"
    refute_includes legacy_schema, "RAKU"
    future_schema = future_schema_sdl
    assert_includes future_schema, "RAKU\n"
    assert_includes future_schema, "\"Use RAKU instead\""
    refute_includes future_schema, "COFFEE_SCRIPT"

    # Introspection:
    query_str = "{ __type(name: \"Language\") { enumValues(includeDeprecated: true) { name deprecationReason } } }"
    legacy_res = exec_query(query_str)
    assert_equal ["RUBY", "PERL6", "COFFEE_SCRIPT"], legacy_res["data"]["__type"]["enumValues"].map { |v| v["name"] }
    assert_equal [nil, nil, nil], legacy_res["data"]["__type"]["enumValues"].map { |v| v["deprecationReason"] }

    future_res = exec_future_query(query_str)
    assert_equal ["RUBY", "PERL6", "RAKU"], future_res["data"]["__type"]["enumValues"].map { |v| v["name"] }
    assert_equal [nil, "Use RAKU instead", nil], future_res["data"]["__type"]["enumValues"].map { |v| v["deprecationReason"] }

    # Runtime return values and inputs:
    assert_equal "COFFEE_SCRIPT", exec_query("{ favoriteLanguage }", context: { favorite_language: "COFFEE_SCRIPT"})["data"]["favoriteLanguage"]
    assert_raises MultifieldSchema::Language::UnresolvedValueError do
      exec_future_query("{ favoriteLanguage }", context: { favorite_language: "COFFEE_SCRIPT"})
    end
    assert_equal "COFFEE_SCRIPT", exec_query("{ favoriteLanguage(lang: COFFEE_SCRIPT) }")["data"]["favoriteLanguage"]
    assert_equal ["Argument 'lang' on Field 'favoriteLanguage' has an invalid value (COFFEE_SCRIPT). Expected type 'Language'."], exec_future_query("{ favoriteLanguage(lang: COFFEE_SCRIPT) }")["errors"].map { |e| e["message"] }

    assert_equal "RAKU", exec_future_query("{ favoriteLanguage }", context: { favorite_language: "RAKU"})["data"]["favoriteLanguage"]
    assert_raises MultifieldSchema::Language::UnresolvedValueError do
      exec_query("{ favoriteLanguage }", context: { favorite_language: "RAKU"})
    end
    assert_equal "RAKU", exec_future_query("{ favoriteLanguage(lang: RAKU) }")["data"]["favoriteLanguage"]
    assert_equal ["Argument 'lang' on Field 'favoriteLanguage' has an invalid value (RAKU). Expected type 'Language'."], exec_query("{ favoriteLanguage(lang: RAKU) }")["errors"].map { |e| e["message"] }
  end

  it "supports multiple types with the same name in orphan_types" do
    legacy_schema = legacy_schema_sdl
    assert_includes legacy_schema, "legacyPlaceField"
    refute_includes legacy_schema, "futurePlaceField"
    assert_equal ["type Place"], legacy_schema.scan("type Place")
    future_schema = future_schema_sdl
    refute_includes future_schema, "legacyPlaceField"
    assert_includes future_schema, "futurePlaceField"
    assert_equal ["type Place"], future_schema.scan("type Place")
  end

  it "supports different resolver arguments" do
    assert_equal "4", exec_query("{ add(left: 1, right: 3) }")["data"]["add"]
    assert_equal ["Argument 'left' on Field 'add' has an invalid value (1.2). Expected type 'Int!'."], exec_query("{ add(left: 1.2, right: 3) }")["errors"].map { |e| e["message"] }

    assert_equal "4.5", exec_future_query("{ add(left: 1.2, right: 3.3) }")["data"]["add"]
    assert_equal "4.2", exec_future_query("{ add(left: 1.2, right: 3) }")["data"]["add"]

    introspection_query_str = "{ __type(name: \"Query\") { fields { name args { type { ofType { name } } } } } }"
    legacy_res = exec_query(introspection_query_str)
    assert_equal ["Int", "Int"], legacy_res["data"]["__type"]["fields"].find { |f| f["name"] == "add" }["args"].map { |a| a["type"]["ofType"]["name"] }
    future_res = exec_future_query(introspection_query_str)
    assert_equal ["Float", "Float"], future_res["data"]["__type"]["fields"].find { |f| f["name"] == "add" }["args"].map { |a| a["type"]["ofType"]["name"] }
  end
end
