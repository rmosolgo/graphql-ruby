require 'spec_helper'

describe GraphQL::Query do
  describe '#execute' do
    let(:query_string) { "
      query getFlavor($cheeseId: Int!) {
        brie: cheese(id: 1)   { ...cheeseFields, ... meatFields, taste: flavor },
        cheese(id: $cheeseId)  { id, ...cheeseFields, ... on Cheese { cheeseKind: flavor }, ... on Meat { cut } }
        fromSource(source: COW) { id }
      }

      fragment cheeseFields on Cheese {
        flavor
      }

      fragment meatFields on Meat {
        cut
      }
    "}
    let(:query) { GraphQL::Query.new(DummySchema, query_string, context: {}, params: {"cheeseId" => 2})}

    it 'returns fields on objects' do
      res = query.execute
      expected = { "getFlavor" => {
          "brie" =>   { "flavor" => "Brie", "taste" => "Brie" },
          "cheese" => { "id" => 2, "flavor" => "Gouda", "cheeseKind" => "Gouda" },
          "fromSource" => [{ "id" => 1 }, {"id" => 2}],
        }}
      assert_equal(expected, res)
    end

    it 'exposes fragments' do
      assert_equal(GraphQL::Nodes::FragmentDefinition, query.fragments['cheeseFields'].class)
    end
  end
end
