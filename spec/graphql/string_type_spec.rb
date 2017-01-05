# frozen_string_literal: true
require "spec_helper"

describe GraphQL::STRING_TYPE do
  let(:string_type) { GraphQL::STRING_TYPE }

  it "is a default scalar" do
    assert_equal(true, string_type.default_scalar?)
  end

  describe "coerce_input" do
    it "accepts strings" do
      assert_equal "str", string_type.coerce_input("str")
    end

    it "doesn't accept other types" do
      assert_equal nil, string_type.coerce_input(100)
      assert_equal nil, string_type.coerce_input(true)
      assert_equal nil, string_type.coerce_input(0.999)
    end
  end
end
