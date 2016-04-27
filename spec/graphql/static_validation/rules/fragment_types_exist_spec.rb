require "spec_helper"

describe GraphQL::StaticValidation::FragmentTypesExist do
  let(:query_string) {"
    query getCheese {
      cheeese(id: 1) {
        ... on Cheese { source }
        ... on Nothing { whatever }
        ... somethingFields
        ... cheeseFields
      }
    }

    fragment somethingFields on Something {
      something
    }
    fragment cheeseFields on Cheese {
      fatContent
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FragmentTypesExist]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "finds non-existent types on fragments" do
    assert_equal(2, errors.length)
    inline_fragment_error =  {
      "message"=>"No such type Something, so it can't be a fragment condition",
      "locations"=>[{"line"=>11, "column"=>5}]
    }
    assert_includes(errors, inline_fragment_error, "on inline fragments")
    fragment_def_error = {
      "message"=>"No such type Nothing, so it can't be a fragment condition",
      "locations"=>[{"line"=>5, "column"=>9}]
    }
    assert_includes(errors, fragment_def_error, "on fragment definitions")
  end
end
