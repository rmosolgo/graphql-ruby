# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::LiteralInput do
  describe ".from_arguments" do
    describe "arguments are prepared" do
      let(:schema) {
        query = GraphQL::ObjectType.define do
          name "Query"

          field :addOneToArgumentValue do
            type !types.Int
            argument :value do
              type !types.Int
              prepare ->(arg) do
                return GraphQL::ExecutionError.new("Can't return more than 3 digits") if arg > 998
                arg + 1
              end
            end
            resolve ->(t, a, c) { a[:value] }
          end
        end

        GraphQL::Schema.define(query: query)
      }

      it "prepares values from query literals" do
        result = schema.execute("{ addOneToArgumentValue(value: 1) }")
        assert_equal(result["data"]["addOneToArgumentValue"], 2)
      end

      it "prepares values from variables" do
        result = schema.execute("query ($value: Int!) { addOneToArgumentValue(value: $value) }", variables: { "value" => 1} )
        assert_equal(result["data"]["addOneToArgumentValue"], 2)
      end

      it "prepares values correctly if called multiple times with different arguments" do
        result = schema.execute("{ first: addOneToArgumentValue(value: 1) second: addOneToArgumentValue(value: 2) }")
        assert_equal(result["data"]["first"], 2)
        assert_equal(result["data"]["second"], 3)
      end

      it "adds message to errors key if an ExecutionError is returned from the prepare function" do
        result = schema.execute("{ addOneToArgumentValue(value: 999) }")
        assert_equal(result["errors"][0]["message"], "Can't return more than 3 digits")
        assert_equal(result["errors"][0]["locations"][0]["line"], 1)
        assert_equal(result["errors"][0]["locations"][0]["column"], 25)
      end
    end
  end
end
