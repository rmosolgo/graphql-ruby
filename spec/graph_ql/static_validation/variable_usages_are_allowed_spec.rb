require 'spec_helper'

describe GraphQL::StaticValidation::VariableUsagesAreAllowed do
  let(:document) { GraphQL.parse('
    query getCheese(
        $goodInt: Int = 1,
        $okInt: Int!,
        $badInt: Int,
        $badStr: String!,
        $goodAnimals: [DairyAnimal!]!,
        $badAnimals: [DairyAnimal]!,
    ) {
      goodCheese:   cheese(id: $goodInt)  { source }
      okCheese:     cheese(id: $okInt)    { source }
      badCheese:    cheese(id: $badInt)   { source }
      badStrCheese: cheese(id: $badStr)   { source }
      cheese(id: 1) {
        similarCheeses(source: $goodAnimals)
        other: similarCheeses(source: $badAnimals)
      }
    }
  ')}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [GraphQL::StaticValidation::VariableUsagesAreAllowed]) }
  let(:errors) { validator.validate(document) }

  it "finds variables used as arguments but don't match the argument's type" do
    assert_equal(3, errors.length)
    expected = [
      {
        "message"=>"Type mismatch on variable $badInt and argument id (Int / Int!)",
        "locations"=>[{"line"=>12, "column"=>28}]
      },
      {
        "message"=>"Type mismatch on variable $badStr and argument id (String! / Int!)",
        "locations"=>[{"line"=>13, "column"=>28}]
      },
      {
        "message"=>"Type mismatch on variable $badAnimals and argument source ([DairyAnimal]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>16, "column"=>31}]
      }
    ]
    assert_equal(expected, errors)
  end
end
