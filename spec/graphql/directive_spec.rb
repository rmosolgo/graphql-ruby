require "spec_helper"

describe GraphQL::Directive do
  let(:result) { DummySchema.execute(query_string, variables: {"t" => true, "f" => false}) }
  describe "on fields" do
    let(:query_string) { %|query directives($t: Boolean!, $f: Boolean!) {
      cheese(id: 1) {
        # plain fields:
        skipFlavor: flavor @skip(if: true)
        dontSkipFlavor: flavor @skip(if: false)
        dontSkipDontIncludeFlavor: flavor @skip(if: false), @include(if: false)
        skipAndInclude: flavor @skip(if: true), @include(if: true)
        includeFlavor: flavor @include(if: $t)
        dontIncludeFlavor: flavor @include(if: $f)
        # fields in fragments
        ... includeIdField
        ... dontIncludeIdField
        ... skipIdField
        ... dontSkipIdField
        }
      }
      fragment includeIdField on Cheese { includeId: id @include(if: true) }
      fragment dontIncludeIdField on Cheese { dontIncludeId: id @include(if: false) }
      fragment skipIdField on Cheese { skipId: id @skip(if: true) }
      fragment dontSkipIdField on Cheese { dontSkipId: id @skip(if: false) }
    |
    }
    it "intercepts fields" do
      expected = { "data" =>{
        "cheese" => {
          "dontSkipFlavor" => "Brie",
          "includeFlavor" => "Brie",
          "includeId" => 1,
          "dontSkipId" => 1,
        },
      }}
      assert_equal(expected, result)
    end
  end
  describe "on fragments spreads and inline fragments" do
    let(:query_string) { %|query directives {
      cheese(id: 1) {
        ... skipFlavorField @skip(if: true)
        ... dontSkipFlavorField @skip(if: false)
        ... includeFlavorField @include(if: true)
        ... dontIncludeFlavorField @include(if: false)


        ... on Cheese @skip(if: true) { skipInlineId: id }
        ... on Cheese @skip(if: false) { dontSkipInlineId: id }
        ... on Cheese @include(if: true) { includeInlineId: id }
        ... on Cheese @include(if: false) { dontIncludeInlineId: id }
        ... @skip(if: true) { skipNoType: id }
        ... @skip(if: false) { dontSkipNoType: id }
        }
      }
      fragment includeFlavorField on Cheese { includeFlavor: flavor  }
      fragment dontIncludeFlavorField on Cheese { dontIncludeFlavor: flavor  }
      fragment skipFlavorField on Cheese { skipFlavor: flavor  }
      fragment dontSkipFlavorField on Cheese { dontSkipFlavor: flavor }
    |}

    it "intercepts fragment spreads" do
      expected = { "data" => {
        "cheese" => {
          "dontSkipFlavor" => "Brie",
          "includeFlavor" => "Brie",
          "dontSkipInlineId" => 1,
          "includeInlineId" => 1,
          "dontSkipNoType" => 1,
        },
      }}
      assert_equal(expected, result)
    end
  end
end
