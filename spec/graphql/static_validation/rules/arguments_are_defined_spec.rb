require "spec_helper"

describe GraphQL::StaticValidation::ArgumentsAreDefined do
  let(:query_string) {"
    query getCheese {
      cheese(id: 1) { source }
      cheese(silly: false) { source }
      searchDairy(product: [{wacky: 1}])
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: SHEEP, nonsense: 1)
      id @skip(something: 3.4)
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::ArgumentsAreDefined]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "finds undefined arguments to fields and directives" do
    assert_equal(4, errors.length)

    query_root_error = {
      "message"=>"Field 'cheese' doesn't accept argument 'silly'",
      "locations"=>[{"line"=>4, "column"=>7}]
    }
    assert_includes(errors, query_root_error)

    input_obj_record = {
      "message"=>"InputObject 'DairyProductInput' doesn't accept argument 'wacky'",
      "locations"=>[{"line"=>5, "column"=>29}]
    }
    assert_includes(errors, input_obj_record)

    fragment_error = {
      "message"=>"Field 'similarCheese' doesn't accept argument 'nonsense'",
      "locations"=>[{"line"=>9, "column"=>7}]
    }
    assert_includes(errors, fragment_error)

    directive_error = {
      "message"=>"Directive 'skip' doesn't accept argument 'something'",
      "locations"=>[{"line"=>10, "column"=>10}]
    }
    assert_includes(errors, directive_error)
  end
end
