# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Authorization do
  module AuthTest
    class BaseArgument < GraphQL::Schema::Argument
      def visible?(context)
        # Hide arguments named `int2` when `context[:hide]` is set
        super && (context[:hide] ? @name != "int2" : true)
      end
    end

    class BaseField < GraphQL::Schema::Field
      argument_class BaseArgument
      def visible?(context)
        super && (context[:hide] ? @name != "int" : true)
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
    end

    module BaseInterface
      include GraphQL::Schema::Interface
    end

    module HiddenInterface
      include BaseInterface

      def self.visible?(ctx)
        super && (ctx[:hide] ? false : true)
      end

      def self.resolve_type(obj, ctx)
        HiddenObject
      end
    end

    class HiddenObject < BaseObject
      implements HiddenInterface
      def self.visible?(ctx)
        super && (ctx[:hide] ? false : true)
      end
    end

    class Query < BaseObject
      field :int, Integer, null: false
      field :int2, Integer, null: false do
        argument :int, Integer, required: false
        argument :int2, Integer, required: false
      end

      field :hidden_object, HiddenObject, null: false, method: :itself
      field :hidden_interface, HiddenInterface, null: false, method: :itself
    end

    class DoHiddenStuff < GraphQL::Schema::RelayClassicMutation
      def self.visible?(ctx)
        super && (ctx[:hide] ? false : true)
      end
    end

    class Mutation < BaseObject
      field :do_hidden_stuff, mutation: DoHiddenStuff
    end

    class Schema < GraphQL::Schema
      query(Query)
      mutation(Mutation)
    end
  end

  describe "applying the visible? method" do
    it "works in queries" do
      res = AuthTest::Schema.execute(" { int int2 } ", context: { hide: true })
      assert_equal 1, res["errors"].size
    end

    it "applies return type visibility to fields" do
      error_queries = {
        "hiddenObject" => "{ hiddenObject { __typename } }",
        "hiddenInterface" => "{ hiddenInterface { __typename } }",
      }

      error_queries.each do |name, q|
        hidden_res = AuthTest::Schema.execute(q, context: { hide: true})
        assert_equal ["Field '#{name}' doesn't exist on type 'Query'"], hidden_res["errors"].map { |e| e["message"] }

        visible_res = AuthTest::Schema.execute(q)
        # Both fields exist; the interface resolves to the object type, though
        assert_equal "HiddenObject", visible_res["data"][name]["__typename"]
      end
    end

    it "uses the mutation for derived fields, inputs and outputs" do
      query = "mutation { doHiddenStuff(input: {}) { __typename } }"
      res = AuthTest::Schema.execute(query, context: { hide: true })
      assert_equal ["Field 'doHiddenStuff' doesn't exist on type 'Mutation'"], res["errors"].map { |e| e["message"] }

      # `#resolve` isn't implemented, so this errors out:
      assert_raises NotImplementedError do
        AuthTest::Schema.execute(query)
      end

      introspection_q = <<-GRAPHQL
        {
          t1: __type(name: "DoHiddenStuffInput") { name }
          t2: __type(name: "DoHiddenStuffPayload") { name }
        }
      GRAPHQL
      hidden_introspection_res = AuthTest::Schema.execute(introspection_q, context: { hide: true })
      assert_nil hidden_introspection_res["data"]["t1"]
      assert_nil hidden_introspection_res["data"]["t2"]

      visible_introspection_res = AuthTest::Schema.execute(introspection_q)
      assert_equal "DoHiddenStuffInput", visible_introspection_res["data"]["t1"]["name"]
      assert_equal "DoHiddenStuffPayload", visible_introspection_res["data"]["t2"]["name"]
    end

    it "uses the base type for edges and connections"

    it "works in introspection" do
      res = AuthTest::Schema.execute <<-GRAPHQL, context: { hide: true }
        {
          __type(name: "Query") {
            fields {
              name
              args { name }
            }
          }

          hiddenObject: __type(name: "HiddenObject") { name }
          hiddenInterface: __type(name: "HiddenInterface") { name }
        }
      GRAPHQL
      query_field_names = res["data"]["__type"]["fields"].map { |f| f["name"] }
      assert_equal ["int2"], query_field_names
      int2_arg_names = res["data"]["__type"]["fields"].first["args"].map { |a| a["name"] }
      assert_equal ["int"], int2_arg_names

      assert_nil res["data"]["hiddenObject"]
      assert_nil res["data"]["hiddenInterface"]
    end
  end
end
