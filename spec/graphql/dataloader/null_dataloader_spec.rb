# frozen_string_literal: true
require "spec_helper"

describe "GraphQL NullDataloader" do
  it "can run_isolated with previously-captured blocks that register lazies" do
    dl = GraphQL::Dataloader::NullDataloader.new
    result = 0
    dl.run_isolated {
      lazy = GraphQL::Execution::Lazy.new { result = 100 }
      dl.lazy_at_depth(1, lazy)
    }
    assert_equal 100, result
  end
end
