# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariableUsagesAreAllowed do
  include StaticValidationHelpers

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
        similarCheese(source: $goodAnimals) { source }
        other: similarCheese(source: $badAnimals) { source }
        tooDeep: similarCheese(source: $deepAnimals) { source }
        nullableCheese(source: $goodAnimals) { source }
        deeplyNullableCheese(source: $deepAnimals) { source }
      }

      milk(id: 1) {
        flavors(limit: $okInt)
      }

      searchDairy(product: [{source: $goodSource}]) {
        ... on Cheese { id }
      }
    }
  '}

  it "finds variables used as arguments but don't match the argument's type" do
    assert_equal(4, errors.length)
    expected = [
      {
        "message"=>"Nullability mismatch on variable $badInt and argument id (Int / Int!)",
        "locations"=>[{"line"=>14, "column"=>28}],
        "fields"=>["query getCheese", "badCheese", "id"],
      },
      {
        "message"=>"Type mismatch on variable $badStr and argument id (String! / Int!)",
        "locations"=>[{"line"=>15, "column"=>28}],
        "fields"=>["query getCheese", "badStrCheese", "id"],
      },
      {
        "message"=>"Nullability mismatch on variable $badAnimals and argument source ([DairyAnimal]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>18, "column"=>30}],
        "fields"=>["query getCheese", "cheese", "other", "source"],
      },
      {
        "message"=>"List dimension mismatch on variable $deepAnimals and argument source ([[DairyAnimal!]!]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>19, "column"=>32}],
        "fields"=>["query getCheese", "cheese", "tooDeep", "source"],
      }
    ]
    assert_equal(expected, errors)
  end


  describe "variables with the same name" do
    let(:query_string) {%|
      query first($int: String) { ... frag1 }
      query second($int: Int!) { ... frag1 }

      fragment frag1 on Query { cheese(id: $int) { flavor } }
    |}

    it "finds an error on the first occurrence of the name" do
      # Here are two variables with the same name but different types
      # The first use is invalid, but the second is valid
      # We should get an error for the first usage (but we don't)
      assert_equal 1, errors.length
    end
  end
end
