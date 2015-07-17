require 'spec_helper'

describe GraphQL::StaticValidation::ArgumentsAreDefined do
  let(:document) { GraphQL.parse("
    query getCheese {
      cheese(id: 1) { source }
      cheese(silly: false) { source }
    }

    fragment cheeseFields on Cheese {
      similarCheeses(source: SHEEP, nonsense: 1)
      id @skip(something: 3.4)
    }
  ")}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [GraphQL::StaticValidation::ArgumentsAreDefined]) }
  let(:errors) { validator.validate(document) }

  it 'finds undefined arguments to fields and directives' do
    assert_equal(3, errors.length)

    query_root_error = {
      "message"=>"Field 'cheese' doesn't accept argument silly",
      "locations"=>[{"line"=>4, "column"=>7}]
    }
    assert_includes(errors, query_root_error)

    fragment_error = {
      "message"=>"Field 'similarCheeses' doesn't accept argument nonsense",
      "locations"=>[{"line"=>8, "column"=>7}]
    }
    assert_includes(errors, fragment_error)

    directive_error = {
      "message"=>"Directive 'skip' doesn't accept argument something",
      "locations"=>[{"line"=>9, "column"=>11}]
    }
    assert_includes(errors, directive_error)
  end
end
