require "spec_helper"

describe GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese(
      $id:        Int = 1,
      $int:       Int = 3.4e24, # can be coerced
      $str:       String!,
      $badInt:    Int = "abc",
      $input:     DairyProductInput = {source: YAK, fatContent: 1},
      $badInput:  DairyProductInput = {source: YAK, fatContent: true},
      $nonNull:  Int! = 1,
    ) {
      cheese1: cheese(id: $id) { source }
      cheese4: cheese(id: $int) { source }
      cheese2: cheese(id: $badInt) { source }
      cheese3: cheese(id: $nonNull) { source }
      search1: searchDairy(product: [$input]) { __typename }
      search2: searchDairy(product: [$badInput]) { __typename }
      __type(name: $str) { name }
    }
  |}

  it "finds default values that don't match their types" do
    expected = [
      {
        "message"=>"Default value for $badInt doesn't match type Int",
        "locations"=>[{"line"=>6, "column"=>7}],
        "fields"=>["query getCheese"],
      },
      {
        "message"=>"Default value for $badInput doesn't match type DairyProductInput",
        "locations"=>[{"line"=>8, "column"=>7}],
        "fields"=>["query getCheese"],
      },
      {
        "message"=>"Non-null variable $nonNull can't have a default value",
        "locations"=>[{"line"=>9, "column"=>7}],
        "fields"=>["query getCheese"],
      }
    ]
    assert_equal(expected, errors)
  end
end
