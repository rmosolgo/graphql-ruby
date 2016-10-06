require "spec_helper"

describe GraphQL::StaticValidation::ArgumentLiteralsAreCompatible do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese {
      stringCheese: cheese(id: "aasdlkfj") { ...cheeseFields }
      cheese(id: 1) { source @skip(if: "whatever") }
      yakSource: searchDairy(product: [{source: COW, fatContent: 1.1}]) { __typename }
      badSource: searchDairy(product: [{source: 1.1}]) { __typename }
      missingSource: searchDairy(product: [{fatContent: 1.1}]) { __typename }
      listCoerce: cheese(id: 1) { similarCheese(source: YAK) { __typename } }
      missingInputField: searchDairy(product: [{source: YAK, wacky: 1}]) { __typename }
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: 4.5) { __typename }
    }
  |}

  it "finds undefined or missing-required arguments to fields and directives" do
    pp errors
    # assert_equal(6, errors.length)

    query_root_error = {
      "message"=>"Argument \"id\" on \"cheese\" has an invalid value, expected type \"Int!\" but received \"aasdlkfj\"",
      "locations"=>[{"line"=>3, "column"=>28}],
      "fields"=>["query getCheese", "stringCheese", "id"],
    }
    assert_includes(errors, query_root_error)

    directive_error = {
      "message"=>"Argument \"if\" on \"skip\" has an invalid value, expected type \"Boolean!\" but received \"whatever\"",
      "locations"=>[{"line"=>4, "column"=>36}],
      "fields"=>["query getCheese", "cheese", "source", "if"],
    }
    assert_includes(errors, directive_error)

    # DON'T actually want this -- it's redundant
    # input_object_error = {
    #   "message"=>"Argument 'product' on Field 'badSource' has an invalid value. Expected type '[DairyProductInput]'.",
    #   "locations"=>[{"line"=>6, "column"=>7}],
    #   "fields"=>["query getCheese", "badSource", "product"],
    # }
    # assert_includes(errors, input_object_error)

    input_object_field_error = {
      "message"=>"Argument \"source\" on \"DairyProductInput\" has an invalid value, expected type \"DairyAnimal!\" but received 1.1",
      "locations"=>[{"line"=>6, "column"=>41}],
      "fields"=>["query getCheese", "badSource", "product", "source"],
    }
    assert_includes(errors, input_object_field_error)

    missing_required_field_error = {
      "message"=>"Arguments for \"DairyProductInput\" are invalid: missing required arguments (\"source\")",
      "locations"=>[{"line"=>7, "column"=>44}],
      "fields"=>["query getCheese", "missingSource", "product"],
    }
    assert_includes(errors, missing_required_field_error)

    missing_input_field_error =  {
      "message"=>"Arguments for \"DairyProductInput\" are invalid: undefined arguments (\"wacky\")",
      "locations"=>[{"line"=>9, "column"=>48}],
      "fields"=>["query getCheese", "missingInputField", "product"],
    }
    assert_includes(errors, missing_input_field_error)

    fragment_error = {
      "message"=>"Argument \"source\" on field \"similarCheese\" has an invalid value, expected type \"[DairyAnimal!]!\" but received 4.5",
      "locations"=>[{"line"=>13, "column"=>21}],
      "fields"=>["fragment cheeseFields", "similarCheese", "source"],
    }
    assert_includes(errors, fragment_error)
  end
end
