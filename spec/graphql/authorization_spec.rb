# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Authorization do
  module AuthTest
    class BaseObject < GraphQL::Schema::Object
    end

    class Query < BaseObject
      field :int, Integer, null: false
      field :int2, Integer, null: false do
        argument :int, Integer, required: false
        argument :int2, Integer, required: false
      end
    end

    class Schema < GraphQL::Schema
      query(Query)

      def self.visible?(member, context)
        # Arbitrary way to filter things out:
        member.respond_to?(:graphql_name) && member.graphql_name != "int"
      end
    end
  end

  describe "applying the visible? method" do
    it "works in queries" do
      res = AuthTest::Schema.execute(" { int }")
      assert_equal 1, res["errors"].size
    end

    it "works in introspection" do
      query_fields = AuthTest::Schema.execute <<-GRAPHQL
        {
          __type(name: "Query") {
            fields {
              name
              args { name }
            }
          }
        }
      GRAPHQL
      query_field_names = query_fields["data"]["__type"]["fields"].map { |f| f["name"] }
      assert_equal ["int2"], query_field_names
      int2_arg_names = query_fields["data"]["__type"]["fields"].first["args"].map { |a| a["name"] }
      assert_equal ["int2"], int2_arg_names
    end
  end
end
