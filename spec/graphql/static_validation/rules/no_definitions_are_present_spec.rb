# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::NoDefinitionsArePresent do
  include StaticValidationHelpers
  describe "when schema definitions are present in the query" do
    let(:query_string) {
      <<-GRAPHQL
      {
        cheese(id: 1) { flavor }
      }

      type Thing {
        stuff: Int
      }

      scalar Date
      GRAPHQL
    }

    it "adds an error" do
      assert_equal 1, errors.length
      err = errors[0]
      assert_equal "Query cannot contain schema definitions", err["message"]
      assert_equal [{"line"=>5, "column"=>7}, {"line"=>9, "column"=>7}], err["locations"]
    end
  end
end
