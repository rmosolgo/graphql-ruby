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

        test = TestInput.to_graphql

        assert_equal test.coerce_input({})[:foo], 'a'
      end
    end
  end
end
