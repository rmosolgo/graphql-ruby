# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::EnumValue do
  describe "#deprecation_reason" do
    it "can be written and read" do
      enum_value = GraphQL::Schema::EnumValue.new(:x, owner: nil)
      assert_nil enum_value.deprecation_reason
      enum_value.deprecation_reason = "No good!"
      assert_equal "No good!", enum_value.deprecation_reason
    end
  end
end
