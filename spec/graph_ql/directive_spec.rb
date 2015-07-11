require 'spec_helper'

describe GraphQL::Directive do
  let(:result) { GraphQL::Query.new(DummySchema, query_string, params: {"t" => true, "f" => false}).execute }
  describe 'on fields' do
    let(:query_string) { %|query directives($t: Boolean!, $f: Boolean!) {
      cheese(id: 1) {
        # plain fields:
        skipFlavor: flavor @skip(if: true)
        dontSkipFlavor: flavor @skip(if: false)
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
    |}
    it 'intercepts fields' do
      expected = {"directives" => {
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
  describe 'on fragments' do
    let(:query_string) { %|query directives {
      cheese(id: 1) {
        ... skipFlavorField @skip(if: true)
        ... dontSkipFlavorField @skip(if: false)
        ... includeFlavorField @include(if: true)
        ... dontIncludeFlavorField @include(if: false)

        ... includeIdField
        ... dontIncludeIdField
        ... skipIdField
        ... dontSkipIdField

        ... on Cheese @skip(if: true) { skipInlineId: id }
        ... on Cheese @skip(if: false) { dontSkipInlineId: id }
        ... on Cheese @include(if: true) { includeInlineId: id }
        ... on Cheese @include(if: false) { dontIncludeInlineId: id }
        }
      }
      fragment includeFlavorField on Cheese { includeFlavor: flavor  }
      fragment dontIncludeFlavorField on Cheese { dontIncludeFlavor: flavor  }
      fragment skipFlavorField on Cheese { skipFlavor: flavor  }
      fragment dontSkipFlavorField on Cheese { dontSkipFlavor: flavor }

      fragment includeIdField on Cheese @include(if: true) { includeId: id  }
      fragment dontIncludeIdField on Cheese @include(if: false) { dontIncludeId: id  }
      fragment skipIdField on Cheese @skip(if: true) { skipId: id  }
      fragment dontSkipIdField on Cheese @skip(if: false) { dontSkipId: id }
    |}

    it 'intercepts fragment spreads' do
      expected = {"directives" => {
        "cheese" => {
          "dontSkipFlavor" => "Brie",
          "includeFlavor" => "Brie",
          "includeId" => 1,
          "dontSkipId" => 1,
          "dontSkipInlineId" => 1,
          "includeInlineId" => 1,
        },
      }}
      assert_equal(expected, result)
    end
  end
end
