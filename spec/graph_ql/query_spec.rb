require 'spec_helper'

describe GraphQL::Query do
  describe '#execute' do
    let(:query_string) { %|
      query getFlavor($cheeseId: Int!) {
        brie: cheese(id: 1)   { ...cheeseFields, ... meatFields, taste: flavor },
        cheese(id: $cheeseId)  {
          __typename,
          id,
          ...cheeseFields,
          ... edibleFields,
          ... on Cheese { cheeseKind: flavor },
          ... on Meat { cut }
        }
        fromSource(source: COW) { id }
        firstSheep: searchDairy(product: {source: SHEEP}) { ... dairyFields }
        favoriteEdible { __typename, fatContent }
      }
      fragment cheeseFields on Cheese { flavor }
      fragment edibleFields on Edible { fatContent }
      fragment meatFields on Meat { cut }
      fragment dairyFields on DairyProduct {
         ... on Cheese { flavor }
         ... on Milk   { source }
      }
    |}
    let(:query) { GraphQL::Query.new(DummySchema, query_string, context: {}, params: {"cheeseId" => 2})}

    it 'returns fields on objects' do
      res = query.execute
      expected = { "getFlavor" => {
          "brie" =>   { "flavor" => "Brie", "taste" => "Brie" },
          "cheese" => {
            "__typename" => "Cheese",
            "id" => 2,
            "fatContent" => 0.3,
            "flavor" => "Gouda",
            "cheeseKind" => "Gouda",
          },
          "fromSource" => [{ "id" => 1 }, {"id" => 2}],
          "firstSheep" => { "flavor" => "Manchego" },
          "favoriteEdible"=>{"__typename"=>"Edible", "fatContent"=>0.04},
        }}
      assert_equal(expected, res)
    end

    it 'exposes fragments' do
      assert_equal(GraphQL::Nodes::FragmentDefinition, query.fragments['cheeseFields'].class)
    end
  end
end
