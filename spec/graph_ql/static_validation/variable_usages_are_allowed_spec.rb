require 'spec_helper'

describe GraphQL::StaticValidation::VariableUsagesAreAllowed do
  let(:document) { GraphQL.parse('
    query getCheese(
        $goodInt: Int = 1,
        $okInt: Int!,
        $badInt: Int,
        $badStr: String!
    ) {
      goodCheese:   cheese(id: $goodInt)  { source }
      okCheese:     cheese(id: $okInt)    { source }
      badCheese:    cheese(id: $badInt)   { source }
      badStrCheese: cheese(id: $badStr)   { source }
    }
  ')}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [GraphQL::StaticValidation::VariableUsagesAreAllowed]) }
  let(:errors) { validator.validate(document) }

  it "finds variables used as arguments but don't match the argument's type" do
    assert_equal(2, errors.length)
    expected = [
      {
        "message"=>"Type mismatch on variable $badInt and argument id (<GraphQL::ScalarType Int> / <GraphQL::NonNullType(Int)>)",
        "locations"=>[{"line"=>10, "column"=>28}]
      },
      {
        "message"=>"Type mismatch on variable $badStr and argument id (<GraphQL::NonNullType(String)> / <GraphQL::NonNullType(Int)>)",
        "locations"=>[{"line"=>11, "column"=>28}]
      }
    ]
    assert_equal(expected, errors)
  end
end
