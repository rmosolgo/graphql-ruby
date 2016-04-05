require 'spec_helper'

describe GraphQL::StaticValidation::VariableUsagesAreAllowed do
  let(:query_string) {'
    query getCheese(
        $goodInt: Int = 1,
        $okInt: Int!,
        $badInt: Int,
        $badStr: String!,
        $goodAnimals: [DairyAnimal!]!,
        $badAnimals: [DairyAnimal]!,
        $deepAnimals: [[DairyAnimal!]!]!,
        $goodSource: DairyAnimal!,
    ) {
      goodCheese:   cheese(id: $goodInt)  { source }
      okCheese:     cheese(id: $okInt)    { source }
      badCheese:    cheese(id: $badInt)   { source }
      badStrCheese: cheese(id: $badStr)   { source }
      cheese(id: 1) {
        similarCheese(source: $goodAnimals)
        other: similarCheese(source: $badAnimals)
        tooDeep: similarCheese(source: $deepAnimals)
        nullableCheese(source: $goodAnimals)
        deeplyNullableCheese(source: $deepAnimals)
      }

      milk(id: 1) {
        flavors(limit: $okInt)
      }

      searchDairy(product: [{source: $goodSource}]) {
        ... on Cheese { id }
      }
    }
  '}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::VariableUsagesAreAllowed]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "finds variables used as arguments but don't match the argument's type" do
    assert_equal(4, errors.length)
    expected = [
      {
        "message"=>"Nullability mismatch on variable $badInt and argument id (Int / Int!)",
        "locations"=>[{"line"=>14, "column"=>28}]
      },
      {
        "message"=>"Type mismatch on variable $badStr and argument id (String! / Int!)",
        "locations"=>[{"line"=>15, "column"=>28}]
      },
      {
        "message"=>"Nullability mismatch on variable $badAnimals and argument source ([DairyAnimal]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>18, "column"=>30}]
      },
      {
        "message"=>"List dimension mismatch on variable $deepAnimals and argument source ([[DairyAnimal!]!]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>19, "column"=>32}]
      }
    ]
    assert_equal(expected, errors)
  end
end
