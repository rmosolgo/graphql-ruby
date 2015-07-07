require 'spec_helper'

describe GraphQL::Query do
  describe '#execute' do
    let(:query_string) { "
      query getFlavor($goudaId: 2) {
        brie: cheese(id: 1) { flavor },
        cheese(id: $goudaId) { flavor }
      }
    "}
    let(:query) { GraphQL::Query.new(DummySchema, query_string, {})}

    it 'returns a result' do
      res = query.execute
      expected = { "getFlavor" => {
          "brie" => { "flavor" => "Brie" },
          "cheese" => { "flavor" => "Gouda"}
        }}
      assert_equal(expected, res)
    end
  end
end
