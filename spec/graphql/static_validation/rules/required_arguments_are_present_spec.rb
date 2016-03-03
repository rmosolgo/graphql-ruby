require "spec_helper"

describe GraphQL::StaticValidation::RequiredArgumentsArePresent do
  let(:query_string) {"
    query getCheese {
      cheese(id: 1) { source }
      cheese { source }
    }

    fragment cheeseFields on Cheese {
      similarCheese(id: 1)
      flavor @include(if: true)
      id @skip
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::RequiredArgumentsArePresent]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "finds undefined arguments to fields and directives" do
    assert_equal(3, errors.length)

    query_root_error = {
      "message"=>"Field 'cheese' is missing required arguments: id",
      "locations"=>[{"line"=>4, "column"=>7}]
    }
    assert_includes(errors, query_root_error)

    fragment_error = {
      "message"=>"Field 'similarCheese' is missing required arguments: source",
      "locations"=>[{"line"=>8, "column"=>7}]
    }
    assert_includes(errors, fragment_error)

    directive_error = {
      "message"=>"Directive 'skip' is missing required arguments: if",
      "locations"=>[{"line"=>10, "column"=>10}]
    }
    assert_includes(errors, directive_error)
  end
end
