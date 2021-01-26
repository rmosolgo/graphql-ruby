# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Deprecation do
  if defined?(ActiveSupport)
    it "uses ActiveSupport::Deprecation.warn when it's available" do
      ActiveSupport::Deprecation.stub :warn, :was_warned do
        assert_equal :was_warned, GraphQL::Deprecation.warn("abcd")
      end
    end
  else
    it "falls back to Kernel.warn" do
      Kernel.stub :warn, :was_kernel_warned do
        assert_equal :was_kernel_warned, GraphQL::Deprecation.warn("abcd")
      end
    end
  end
end
