# frozen_string_literal: true
require "spec_helper"

describe GraphQL::INT_TYPE do
  describe "coerce_input" do
    it "accepts ints and floats" do
      assert_equal 1, GraphQL::INT_TYPE.coerce_isolated_input(1)
      assert_equal 6, GraphQL::INT_TYPE.coerce_isolated_input(6.1)
    end

    it "rejects other types" do
      assert_nil GraphQL::INT_TYPE.coerce_isolated_input("55")
      assert_nil GraphQL::INT_TYPE.coerce_isolated_input(true)
    end

    it "accepts result values in bounds" do
      assert_equal 0, GraphQL::INT_TYPE.coerce_result(0, nil)
      assert_equal (2**31) - 1, GraphQL::INT_TYPE.coerce_result((2**31) - 1, nil)
      assert_equal -(2**31), GraphQL::INT_TYPE.coerce_result(-(2**31), nil)
    end

    it "raises on values out of bounds" do
      assert_raises(GraphQL::IntegerEncodingError) { GraphQL::INT_TYPE.coerce_result(2**31, nil) }
      assert_raises(GraphQL::IntegerEncodingError) { GraphQL::INT_TYPE.coerce_result(-(2**31 + 1), nil) }
    end
  end
end
