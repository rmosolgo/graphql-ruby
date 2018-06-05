# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::ArgumentNamesAreUnique do
  include StaticValidationHelpers

  describe "field arguments" do
    let(:query_string) { <<-GRAPHQL
    query GetStuff {
      c1: cheese(id: 1, id: 2) { flavor }
      c2: cheese(id: 2) { flavor }
    }
    GRAPHQL
    }

    it "finds duplicate names" do
      assert_equal 1, errors.size

      error = errors.first
      assert_equal 'There can be only one argument named "id"', error["message"]
      assert_equal [{ "line" => 2, "column" => 18}, { "line" => 2, "column" => 25 }], error["locations"]
      assert_equal ["query GetStuff", "c1"], error["fields"]
    end
  end

  describe "directive arguments" do
    let(:query_string) { <<-GRAPHQL
    query GetStuff {
      c1: cheese(id: 1) @include(if: true, if: true) { flavor }
      c2: cheese(id: 2) @include(if: true) { flavor }
    }
    GRAPHQL
    }

    it "finds duplicate names" do
      assert_equal 1, errors.size

      error = errors.first
      assert_equal 'There can be only one argument named "if"', error["message"]
      assert_equal [{ "line" => 2, "column" => 34}, { "line" => 2, "column" => 44 }], error["locations"]
      assert_equal ["query GetStuff", "c1"], error["fields"]
    end
  end
end
