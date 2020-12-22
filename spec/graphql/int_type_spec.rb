# frozen_string_literal: true
require "spec_helper"

describe GraphQL::INT_TYPE do
  describe "coerce_input" do
    it "accepts ints within the bounds" do
      assert_equal -(2**31), GraphQL::INT_TYPE.coerce_isolated_input(-(2**31))
      assert_equal 1, GraphQL::INT_TYPE.coerce_isolated_input(1)
      assert_equal (2**31)-1, GraphQL::INT_TYPE.coerce_isolated_input((2**31)-1)
    end

    it "rejects other types and ints outside the bounds" do
      assert_nil GraphQL::INT_TYPE.coerce_isolated_input("55")
      assert_nil GraphQL::INT_TYPE.coerce_isolated_input(true)
      assert_nil GraphQL::INT_TYPE.coerce_isolated_input(6.1)
      assert_nil GraphQL::INT_TYPE.coerce_isolated_input(2**31)
      assert_nil GraphQL::INT_TYPE.coerce_isolated_input(-(2**31 + 1))
    end

    describe "handling boundaries" do
      let(:context) { GraphQL::Query.new(Dummy::Schema, "{ __typename }").context }

      it "accepts result values in bounds" do
        assert_equal 0, GraphQL::INT_TYPE.coerce_result(0, context)
        assert_equal (2**31) - 1, GraphQL::INT_TYPE.coerce_result((2**31) - 1, context)
        assert_equal -(2**31), GraphQL::INT_TYPE.coerce_result(-(2**31), context)
      end

      it "replaces values, if configured to do so" do
        assert_equal Dummy::Schema::MAGIC_INT_COERCE_VALUE, GraphQL::INT_TYPE.coerce_result(99**99, context)
      end

      it "raises on values out of bounds" do
        assert_raises(GraphQL::IntegerEncodingError) { GraphQL::INT_TYPE.coerce_result(2**31, context) }
        assert_raises(GraphQL::IntegerEncodingError) { GraphQL::INT_TYPE.coerce_result(-(2**31 + 1), context) }
      end
    end
  end
end
