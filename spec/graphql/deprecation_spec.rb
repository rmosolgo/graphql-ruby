# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Deprecation do
  it "falls back to Kernel.warn" do
    Kernel.stub :warn, :was_kernel_warned do
      assert_equal :was_kernel_warned, GraphQL::Deprecation.warn("abcd")
    end
  end
end
