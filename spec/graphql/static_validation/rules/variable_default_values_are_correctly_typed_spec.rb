require "spec_helper"

describe GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped do
  let(:query_string) {%|
    query getCheese(
      $id:        Int = 1,
      $int:       Int = 3.4e24, # can be coerced
      $str:       String!,
      $badFloat:  Float = true,
      $badInt:    Int = "abc",
      $input:     DairyProductInput = {source: YAK, fatContent: 1},
      $badInput:  DairyProductInput = {source: YAK, fatContent: true},
      $nonNull:  Int! = 1,
    ) {
      cheese(id: $id) { source }
    }
  |}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "finds default values that don't match their types" do
    expected = [
      {
        "message"=>"Default value for $badFloat doesn't match type Float",
        "locations"=>[{"line"=>6, "column"=>7}]
      },
      {
        "message"=>"Default value for $badInt doesn't match type Int",
        "locations"=>[{"line"=>7, "column"=>7}]
      },
      {
        "message"=>"Default value for $badInput doesn't match type DairyProductInput",
        "locations"=>[{"line"=>9, "column"=>7}]
      },
      {
        "message"=>"Non-null variable $nonNull can't have a default value",
        "locations"=>[{"line"=>10, "column"=>7}]
      }
    ]
    assert_equal(expected, errors)
  end
end
