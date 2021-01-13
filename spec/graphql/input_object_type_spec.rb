# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::InputObjectType do
  describe 'default values' do
    describe 'when the type is an enum with underlying ruby values' do
      it 'provides the default value' do
        class TestEnum < GraphQL::Schema::Enum
          value 'A', 'Represents an authorized agent in our system.', value: 'a'
          value 'B', 'Agent is disabled, web app access is denied.', value: 'b'
        end

        class TestInput < GraphQL::Schema::InputObject
          argument :foo, TestEnum, 'TestEnum', required: false, default_value: 'a'
        end

        test_input_type = TestInput
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
  end
end
