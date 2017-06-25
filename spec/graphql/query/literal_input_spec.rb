# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::LiteralInput do
  describe ".from_arguments" do
    describe "arguments are prepared" do
      let(:schema) {
        type = GraphQL::ObjectType.define do
          name "SomeType"

          field :addToArgumentValue do
            type !types.Int
            argument :value do
              type types.Int
              default_value 3
              prepare ->(arg, ctx) do
                return GraphQL::ExecutionError.new("Can't return more than 3 digits") if arg > 998
                arg + ctx[:val]
              end
            end
            resolve ->(t, a, c) { a[:value] }
          end

          field :fieldWithArgumentThatIsBadByDefault do
            type types.Int
            argument :value do
              type types.Int
              default_value 7
              prepare ->(arg, ctx) do
                GraphQL::ExecutionError.new("Always bad")
              end
            end

            resolve ->(*args) { 42 }
          end
        end

        query = GraphQL::ObjectType.define do
          name "Query"

          field :top, type, resolve: ->(_, _, _) { true }
        end

        GraphQL::Schema.define(query: query)
      }

      it "prepares values from query literals" do
        result = schema.execute("{ top { addToArgumentValue(value: 1) } }", context: { val: 1 })
        assert_equal(result["data"]["top"]["addToArgumentValue"], 2)
      end

      it "prepares default values" do
        result = schema.execute("{ top { addToArgumentValue } }", context: { val: 4 })
        assert_equal(7, result["data"]["top"]["addToArgumentValue"])
      end

      it "raises an execution error if the default value is bad" do
        result = schema.execute("{ top { fieldWithArgumentThatIsBadByDefault } }", context: { })
        assert_equal(result["data"], {
          "top"=>{
            "fieldWithArgumentThatIsBadByDefault"=>nil}
        })
        assert_equal(result["errors"], [
          {"message"=>"Always bad",
           "locations"=>[{"line"=>1, "column"=>9}],
           "path"=>["top", "fieldWithArgumentThatIsBadByDefault"]}
        ])
      end

      it "prepares values from variables" do
        result = schema.execute("query ($value: Int!) { top { addToArgumentValue(value: $value) } }", variables: { "value" => 1}, context: { val: 2 } )
        assert_equal(result["data"]["top"]["addToArgumentValue"], 3)
      end

      it "prepares values correctly if called multiple times with different arguments" do
        result = schema.execute("{ top { first: addToArgumentValue(value: 1) second: addToArgumentValue(value: 2) } }", context: { val: 3 })
        assert_equal(result["data"]["top"]["first"], 4)
        assert_equal(result["data"]["top"]["second"], 5)
      end

      it "adds message to errors key if an ExecutionError is returned from the prepare function" do
        result = schema.execute("{ top { addToArgumentValue(value: 999) } }")
        assert_equal(result["data"]["top"], nil)
        assert_equal(result["errors"][0]["message"], "Can't return more than 3 digits")
        assert_equal(result["errors"][0]["locations"][0]["line"], 1)
        assert_equal(result["errors"][0]["locations"][0]["column"], 28)
        assert_equal(result["errors"][0]["path"], ["top", "addToArgumentValue"])
      end
    end
  end
end
