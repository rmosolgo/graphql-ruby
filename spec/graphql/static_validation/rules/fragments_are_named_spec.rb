require "spec_helper"

describe GraphQL::StaticValidation::FragmentTypesExist do
  let(:query_string) {"
    fragment on Cheese {
      id
      flavor
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FragmentsAreNamed]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }

  it "finds non-existent types on fragments" do
    assert_equal(1, errors.length)
    fragment_def_error = {
      "message"=>"Fragment definition has no name",
      "locations"=>[{"line"=>2, "column"=>5}],
      "fields"=>["fragment "],
    }
    assert_includes(errors, fragment_def_error, "on fragment definitions")
  end
end
