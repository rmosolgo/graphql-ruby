require 'spec_helper'

describe GraphQL::Directive do
  let(:result) { GraphQL::Query.new(DummySchema, query_string, params: {"t" => true, "f" => false}).execute }
  describe 'on fields' do
    let(:query_string) { %|query getName($t: Boolean!, $f: Boolean!) {
      cheese(id: 1) {
        flavor,
        skipFlavor: flavor @skip(if: true)
        dontSkipFlavor: flavor @skip(if: false)
        includeFlavor: flavor @include(if: $t)
        dontIncludeFlavor: flavor @include(if: $f)
        }
      }|}
    it 'intercepts fields' do
      expected = {"getName" => {
        "cheese" => {
          "flavor" => "Brie",
          "dontSkipFlavor" => "Brie",
          "includeFlavor" => "Brie",
        },
      }}
      assert_equal(expected, result)
    end

  end
end
