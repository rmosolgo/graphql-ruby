# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::RequiredArgumentsArePresent do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { ...cheeseFields }
      cheese { source }
    }

    fragment cheeseFields on Cheese {
      similarCheese() { __typename }
      flavor @include(if: true)
      id @skip
    }
  "}

  it "finds undefined arguments to fields and directives" do
    assert_equal(3, errors.length)

    query_root_error = {
      "message"=>"Field 'cheese' is missing required arguments: id",
      "locations"=>[{"line"=>4, "column"=>7}],
      "fields"=>["query getCheese", "cheese"],
    }
    assert_includes(errors, query_root_error)

    fragment_error = {
      "message"=>"Field 'similarCheese' is missing required arguments: source",
      "locations"=>[{"line"=>8, "column"=>7}],
      "fields"=>["fragment cheeseFields", "similarCheese"],
    }
    assert_includes(errors, fragment_error)

    directive_error = {
      "message"=>"Directive 'skip' is missing required arguments: if",
      "locations"=>[{"line"=>10, "column"=>10}],
      "fields"=>["fragment cheeseFields", "id"],
    }
    assert_includes(errors, directive_error)
  end

  describe "dynamic fields" do
    let(:query_string) {"
      query {
        __type { name }
      }
    "}

    it "finds undefined required arguments" do
      expected_errors = [
        {
          "message"=>"Field '__type' is missing required arguments: name",
          "locations"=>[
            {"line"=>3, "column"=>9}
          ],
          "fields"=>["query", "__type"],
        }
      ]
      assert_equal(expected_errors, errors)
    end
  end
end
