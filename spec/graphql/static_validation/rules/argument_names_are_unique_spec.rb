# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::ArgumentNamesAreUnique do
  include StaticValidationHelpers

  let(:query_string) { <<-GRAPHQL
  query GetStuff {
    c1: cheese(id: 1, id: 2) { flavor }
    c2: cheese(id: 2) { flavor }
  }
  GRAPHQL
  }

  it "finds duplicate argument names" do
    assert_equal 1, errors.size

    error = errors.first
    assert_equal 'There can be only one argument named "id"', error["message"]
    assert_equal [{ "line" => 2, "column" => 16}, { "line" => 2, "column" => 23 }], error["locations"]
    assert_equal ["query GetStuff", "c1"], error["fields"]
  end
end
