# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::LiteralInput do
  describe ".from_arguments" do
    describe "arguments are prepared" do
      class LiteralInputTestSchema < GraphQL::Schema
        class SomeType < GraphQL::Schema::Object
          field :add_to_argument_value, Integer, null: false do
            argument :value, Integer, required: false, default_value: 3,
              prepare: ->(arg, ctx) {
                return GraphQL::ExecutionError.new("Can't return more than 3 digits") if arg > 998
                arg + ctx[:val]
              }
          end

          def add_to_argument_value(value:)
            value
          end

          field :field_with_argument_that_is_bad_by_default, Integer do
            argument :value, Integer, required: false, default_value: 7,
              prepare: ->(arg, ctx) {
                raise GraphQL::ExecutionError.new("Always bad")
              }
          end

          def field_with_argument_that_is_bad_by_default(value:)
            42
          end
        end

        class Query < GraphQL::Schema::Object
          field :top, SomeType, null: false

          def top
            true
          end
        end

        query(Query)
      end

      let(:schema) { LiteralInputTestSchema }

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
        assert_nil result.fetch("data")
        assert_equal(result["errors"][0]["message"], "Can't return more than 3 digits")
        assert_equal(result["errors"][0]["locations"][0]["line"], 1)
        # TODO: on the old runtime, this was `28`, the position ov `value:`, which was better.
        assert_equal(9, result["errors"][0]["locations"][0]["column"])
        assert_equal(result["errors"][0]["path"], ["top", "addToArgumentValue"])
      end
    end
  end
end
