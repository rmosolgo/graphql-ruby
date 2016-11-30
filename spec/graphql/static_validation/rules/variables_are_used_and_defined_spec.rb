# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariablesAreUsedAndDefined do
  include StaticValidationHelpers

  let(:query_string) {'
    query getCheese(
      $usedVar: Int!,
      $usedInnerVar: [DairyAnimal!]!,
      $usedInlineFragmentVar: Int!,
      $usedFragmentVar: Int!,
      $notUsedVar: Int!,
    ) {
      c1: cheese(id: $usedVar) {
        __typename
      }
      ... on Query {
        c2: cheese(id: $usedInlineFragmentVar) {
          similarCheese(source: $usedInnerVar) { __typename }
        }

      }

      c3: cheese(id: $undefinedVar) { __typename }

      ... outerCheeseFields
    }

    fragment outerCheeseFields on Query {
      ... innerCheeseFields
    }

    fragment innerCheeseFields on Query {
      c4: cheese(id: $undefinedFragmentVar) { __typename }
      c5: cheese(id: $usedFragmentVar) { __typename }
    }
  '}

  it "finds variables which are used-but-not-defined or defined-but-not-used" do
    expected = [
      {
        "message"=>"Variable $notUsedVar is declared by getCheese but not used",
        "locations"=>[{"line"=>2, "column"=>5}],
        "fields"=>["query getCheese"],
      },
      {
        "message"=>"Variable $undefinedVar is used by getCheese but not declared",
        "locations"=>[{"line"=>19, "column"=>22}],
        "fields"=>["query getCheese", "c3", "id"],
      },
      {
        "message"=>"Variable $undefinedFragmentVar is used by innerCheeseFields but not declared",
        "locations"=>[{"line"=>29, "column"=>22}],
        "fields"=>["fragment innerCheeseFields", "c4", "id"],
      },
    ]

    assert_equal(expected, errors)
  end
end
