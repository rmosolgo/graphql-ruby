require 'spec_helper'

describe GraphQL::Directive do
  let(:result) { GraphQL::Query.new(DummySchema, query_string, params: {"t" => true, "f" => false}).execute }
  describe 'on fields' do
    let(:query_string) { %|query getName($t: Boolean!, $f: Boolean!) {
      cheese(id: 1) {
        # plain fields:
        skipFlavor: flavor @skip(if: true)
        dontSkipFlavor: flavor @skip(if: false)
        includeFlavor: flavor @include(if: $t)
        dontIncludeFlavor: flavor @include(if: $f)
        # fragment spreads:
        ... dontIncludeIdField @include(if: false)
        ... includeIdField @include(if: true)
        ... skipIdField @skip(if: true)
        ... dontSkipIdField @skip(if: false)
        # directive-on-fragment-defn
        # inline fragments
        }
      }
      fragment includeIdField on Cheese { includeId: id }
      fragment dontIncludeIdField on Cheese { dontIncludeId: id }
      fragment skipIdField on Cheese { skipId: id }
      fragment dontSkipIdField on Cheese { dontSkipId: id }
    |}
    it 'intercepts fields' do
      expected = {"getName" => {
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
end
