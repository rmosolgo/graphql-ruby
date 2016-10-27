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
    # `wacky` above is handled by ArgumentsAreDefined, so only 6 are tested below
    assert_equal(8, errors.length)

    query_root_error = {
      "message"=>"Argument 'id' on Field 'stringCheese' has an invalid value. Expected type 'Int!'.",
      "locations"=>[{"line"=>3, "column"=>7}],
      "fields"=>["query getCheese", "stringCheese", "id"],
    }
    assert_includes(errors, query_root_error)

    directive_error = {
      "message"=>"Argument 'if' on Directive 'skip' has an invalid value. Expected type 'Boolean!'.",
      "locations"=>[{"line"=>4, "column"=>30}],
      "fields"=>["query getCheese", "cheese", "source", "if"],
    }
    assert_includes(errors, directive_error)

    input_object_error = {
      "message"=>"Argument 'product' on Field 'badSource' has an invalid value. Expected type '[DairyProductInput]'.",
      "locations"=>[{"line"=>6, "column"=>7}],
      "fields"=>["query getCheese", "badSource", "product"],
    }
    assert_includes(errors, input_object_error)

    input_object_field_error = {
      "message"=>"Argument 'source' on InputObject 'DairyProductInput' has an invalid value. Expected type 'DairyAnimal!'.",
      "locations"=>[{"line"=>6, "column"=>40}],
      "fields"=>["query getCheese", "badSource", "product", "source"],
    }
    assert_includes(errors, input_object_field_error)

    missing_required_field_error = {
      "message"=>"Argument 'product' on Field 'missingSource' has an invalid value. Expected type '[DairyProductInput]'.",
      "locations"=>[{"line"=>7, "column"=>7}],
      "fields"=>["query getCheese", "missingSource", "product"],
    }
    assert_includes(errors, missing_required_field_error)

    fragment_error = {
      "message"=>"Argument 'source' on Field 'similarCheese' has an invalid value. Expected type '[DairyAnimal!]!'.",
      "locations"=>[{"line"=>13, "column"=>7}],
      "fields"=>["fragment cheeseFields", "similarCheese", "source"],
    }
    assert_includes(errors, fragment_error)
  end
end
