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
      "message"=>"Required arguments missing from \"Query.cheese\": \"id\"",
      "locations"=>[{"line"=>4, "column"=>7}],
      "fields"=>["query getCheese", "cheese"],
    }
    assert_includes(errors, query_root_error)

    fragment_error = {
      "message"=>"Required arguments missing from \"Cheese.similarCheese\": \"source\"",
      "locations"=>[{"line"=>8, "column"=>7}],
      "fields"=>["fragment cheeseFields", "similarCheese"],
    }
    assert_includes(errors, fragment_error)

    directive_error = {
      "message"=>"Required arguments missing from \"@skip\": \"if\"",
      "locations"=>[{"line"=>10, "column"=>10}],
      "fields"=>["fragment cheeseFields", "id"],
    }
    assert_includes(errors, directive_error)
  end
end
