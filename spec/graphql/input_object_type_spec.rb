# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::InputObjectType do
  describe 'default values' do
    describe 'when the type is an enum with underlying ruby values' do
      it 'provides the default value' do
        TestEnum = GraphQL::EnumType.define do
          name 'Test'

          value 'A', 'Represents an authorized agent in our system.', value: 'a'
          value 'B', 'Agent is disabled, web app access is denied.', value: 'b'
        end

        class TestInput < GraphQL::Schema::InputObject
          argument :foo, TestEnum, 'TestEnum', required: false, default_value: 'a'
        end

        test_input_type = TestInput.to_graphql
        default_test_input_value = test_input_type.coerce_isolated_input({})
        assert_equal default_test_input_value[:foo], 'a'
      end
    end

    describe "when it's an empty object" do
      it "is passed in" do
        input_obj = GraphQL::InputObjectType.define do
          name "InputObj"
          argument :s, types.String
        end

        query = GraphQL::ObjectType.define do
          name "Query"
          field(:f, types.String) do
            argument(:arg, input_obj, default_value: {})
            resolve ->(obj, args, ctx) {
              args[:arg].to_h.inspect
            }
          end
        end

        schema = GraphQL::Schema.define do
          query(query)
        end

        res = schema.execute("{ f } ")
        assert_equal "{}", res["data"]["f"]
      end
    end

    describe "when value is provided" do
      it "replaces null values when :null or :blank replace flag values are provided" do
        input_obj_schema = Class.new(GraphQL::Schema::InputObject) do
          graphql_name "InputObj"
          argument :a, String, default_value: "default_value_a", replace: :nil, required: false
          argument :b, String, default_value: "default_value_b", replace: :blank, required: false
        end

        test_input_type = input_obj_schema.to_graphql
        default_test_input_values = test_input_type.coerce_isolated_input({"a" => nil, "b" => nil})
        assert_equal default_test_input_values.values, ['default_value_a', 'default_value_b']
      end

      it "replaces blank values only when :blank replace flag value is provided" do
        input_obj_schema = Class.new(GraphQL::Schema::InputObject) do
          graphql_name "InputObj"
          argument :a, String, default_value: "default_value_a", replace: :nil, required: false
          argument :b, String, default_value: "b_was_replaced", replace: :blank, required: false
          argument :c, [String], default_value: ["default_value_c"], replace: :nil, required: false
          argument :d, [String], default_value: ["d_was_replaced"], replace: :blank, required: false
        end

        test_input_type = input_obj_schema.to_graphql
        default_test_input_values = test_input_type.coerce_isolated_input({"a" => '', "b" => '', "c" => [], "d" => []})
        assert_equal default_test_input_values.values, ['', 'b_was_replaced', [], ['d_was_replaced']]
      end

      it "doesn't replace provided values when the replace flag is set to :none" do
        input_obj_schema = Class.new(GraphQL::Schema::InputObject) do
          graphql_name "InputObj"
          argument :a, String, default_value: "default_value_a", replace: :none, required: false
          argument :b, [String], default_value: ["default_value_b"], replace: :none, required: false
        end

        test_input_type = input_obj_schema.to_graphql
        default_test_input_values = test_input_type.coerce_isolated_input({"a" => '', "b" => nil})
        assert_equal default_test_input_values.values, ['', nil]
      end
    end
  end
end
