# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::LiteralInput do
  describe ".from_arguments" do
    describe "arguments are prepared" do
      let(:schema) {
        query = GraphQL::ObjectType.define do
          name "Query"

          field :addToArgumentValue do
            type !types.Int
            argument :value do
              type !types.Int
              prepare ->(arg, ctx) do
                return GraphQL::ExecutionError.new("Can't return more than 3 digits") if arg > 998
                arg + ctx[:val]
              end
            end
            resolve ->(t, a, c) { a[:value] }
          end
        end

        GraphQL::Schema.define(query: query)
      }

      it "prepares values from query literals" do
        result = schema.execute("{ addToArgumentValue(value: 1) }", context: { val: 1 })
        assert_equal(result["data"]["addToArgumentValue"], 2)
      end

      it "prepares values from variables" do
        result = schema.execute("query ($value: Int!) { addToArgumentValue(value: $value) }", variables: { "value" => 1}, context: { val: 2 } )
        assert_equal(result["data"]["addToArgumentValue"], 3)
      end

      it "prepares values correctly if called multiple times with different arguments" do
        result = schema.execute("{ first: addToArgumentValue(value: 1) second: addToArgumentValue(value: 2) }", context: { val: 3 })
        assert_equal(result["data"]["first"], 4)
        assert_equal(result["data"]["second"], 5)
      end

      it "adds message to errors key if an ExecutionError is returned from the prepare function" do
        result = schema.execute("{ addToArgumentValue(value: 999) }")
        assert_equal(result["errors"][0]["message"], "Can't return more than 3 digits")
        assert_equal(result["errors"][0]["locations"][0]["line"], 1)
        assert_equal(result["errors"][0]["locations"][0]["column"], 22)
      end
    end
  end
end
