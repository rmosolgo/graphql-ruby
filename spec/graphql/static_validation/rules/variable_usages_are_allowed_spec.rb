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

  describe "input objects that are out of place" do
    let(:query_string) { <<-GRAPHQL
      query getCheese($id: ID!) {
        cheese(id: {blah: $id} ) {
          __typename @nonsense(id: {blah: $id})
          nonsense(id: {blah: {blah: $id}})
        }
      }
    GRAPHQL
    }

    it "adds an error" do
      assert_equal 3, errors.length
      assert_equal "Argument 'id' on Field 'cheese' has an invalid value. Expected type 'Int!'.", errors[0]["message"]
    end
  end
end
