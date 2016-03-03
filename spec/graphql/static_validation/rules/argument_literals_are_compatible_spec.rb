require "spec_helper"

describe GraphQL::StaticValidation::ArgumentLiteralsAreCompatible do
  let(:query_string) {%|
    query getCheese {
      cheese(id: "aasdlkfj") { source }
      cheese(id: 1) { source @skip(if: {id: 1})}
      yakSource: searchDairy(product: [{source: COW, fatContent: 1.1}]) { source }
      badSource: searchDairy(product: [{source: 1.1}]) { source }
      missingSource: searchDairy(product: [{fatContent: 1.1}]) { source }
      listCoerce: cheese(id: 1) { similarCheese(source: YAK) }
      missingInputField: searchDairy(product: [{source: YAK, wacky: 1}])
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: 4.5)
    }
  |}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::ArgumentLiteralsAreCompatible]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "finds undefined or missing-required arguments to fields and directives" do
    assert_equal(6, errors.length)

    query_root_error = {
      "message"=>"Argument 'id' on Field 'cheese' has an invalid value",
      "locations"=>[{"line"=>3, "column"=>7}]
    }
    assert_includes(errors, query_root_error)

    directive_error = {
      "message"=>"Argument 'if' on Directive 'skip' has an invalid value",
      "locations"=>[{"line"=>4, "column"=>30}]
    }
    assert_includes(errors, directive_error)

    input_object_error = {
      "message"=>"Argument 'product' on Field 'badSource' has an invalid value",
      "locations"=>[{"line"=>6, "column"=>7}]
    }
    assert_includes(errors, input_object_error)

    input_object_field_error = {
      "message"=>"Argument 'source' on InputObject 'DairyProductInput' has an invalid value",
      "locations"=>[{"line"=>6, "column"=>40}]
    }
    assert_includes(errors, input_object_field_error)

    missing_required_field_error = {
      "message"=>"Argument 'product' on Field 'missingSource' has an invalid value",
      "locations"=>[{"line"=>7, "column"=>7}]
    }
    assert_includes(errors, missing_required_field_error)

    fragment_error = {
      "message"=>"Argument 'source' on Field 'similarCheese' has an invalid value",
      "locations"=>[{"line"=>13, "column"=>7}]
    }
    assert_includes(errors, fragment_error)
  end
end
