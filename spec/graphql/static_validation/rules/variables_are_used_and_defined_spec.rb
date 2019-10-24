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
        "path"=>["query getCheese"],
        "extensions"=>{"code"=>"variableNotUsed", "variableName"=>"notUsedVar"}
      },
      {
        "message"=>"Variable $undefinedVar is used by getCheese but not declared",
        "locations"=>[{"line"=>19, "column"=>22}],
        "path"=>["query getCheese", "c3", "id"],
        "extensions"=>{"code"=>"variableNotDefined", "variableName"=>"undefinedVar"}
      },
      {
        "message"=>"Variable $undefinedFragmentVar is used by innerCheeseFields but not declared",
        "locations"=>[{"line"=>29, "column"=>22}],
        "path"=>["fragment innerCheeseFields", "c4", "id"],
        "extensions"=>{"code"=>"variableNotDefined", "variableName"=>"undefinedFragmentVar"}
      },
    ]

    assert_equal(expected, errors)
  end

  describe "usages in directives on fragment spreads" do
    let(:query_string) {
      <<-GRAPHQL
      query($f: Boolean!){
        ...F @include(if: $f)
      }
      fragment F on Query {
        __typename
      }
      GRAPHQL
    }

    it "finds usages" do
      assert_equal([], errors)
    end
  end
end
