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
  end
end
