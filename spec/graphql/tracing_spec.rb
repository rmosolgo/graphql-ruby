# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing do
  describe ".trace" do
    it "delivers the metadata to send_trace, with result and key" do
      returned_value = nil
      traces = TestTracing.with_trace  do
        returned_value = GraphQL::Tracing.trace("something", { some_stuff: true }) do
          "do stuff"
        end
      end

      assert_equal 1, traces.length
      trace = traces.first
      assert_equal "something", trace[:key]
      assert_equal true, trace[:some_stuff]
      # Any override of .trace must return the block's return value
      assert_equal "do stuff", returned_value
    end
  end
end
