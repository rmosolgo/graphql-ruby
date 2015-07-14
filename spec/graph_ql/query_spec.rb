require 'spec_helper'

describe GraphQL::Query do
  describe '#execute' do
    let(:query_string) { %|
      query getFlavor($cheeseId: Int!) {
        brie: cheese(id: 1)   { ...cheeseFields, ... milkFields, taste: flavor },
        cheese(id: $cheeseId)  {
          __typename,
          id,
          ...cheeseFields,
          ... edibleFields,
          ... on Cheese { cheeseKind: flavor },
          ... on Milk { source }
        }
        fromSource(source: COW) { id }
        firstSheep: searchDairy(product: {source: SHEEP}) { ... dairyFields }
        favoriteEdible { __typename, fatContent }
      }
      fragment cheeseFields on Cheese { flavor }
      fragment edibleFields on Edible { fatContent }
      fragment milkFields on Milk { source }
      fragment dairyFields on DairyProduct {
         ... on Cheese { flavor }
         ... on Milk   { source }
      }
    |}
    let(:debug) { false }
    let(:query) { GraphQL::Query.new(DummySchema, query_string, context: {}, params: {"cheeseId" => 2}, debug: debug)}
    let(:result) { query.result }

    it 'returns fields on objects' do
      expected = {"data"=> { "getFlavor" => {
          "brie" =>   { "flavor" => "Brie", "taste" => "Brie" },
          "cheese" => {
            "__typename" => "Cheese",
            "id" => 2,
            "flavor" => "Gouda",
            "fatContent" => 0.3,
            "cheeseKind" => "Gouda",
          },
          "fromSource" => [{ "id" => 1 }, {"id" => 2}],
          "firstSheep" => { "flavor" => "Manchego" },
          "favoriteEdible"=>{"__typename"=>"Milk", "fatContent"=>0.04},
      }}}
      assert_equal(expected, result)
    end

    it 'exposes fragments' do
      assert_equal(GraphQL::Nodes::FragmentDefinition, query.fragments['cheeseFields'].class)
    end

    describe 'runtime errors' do
      let(:query_string) {%| query noMilk { error }|}
      it 'turns into error messages' do
        expected = {"errors"=>[
          {"message"=>"Something went wrong during query execution: This error was raised on purpose"}
        ]}
        assert_equal(expected, result)
      end

      describe 'if debug: true' do
        let(:debug) { true }
        it 'raises error' do
          assert_raises(RuntimeError) { result }
        end
      end
    end


    describe 'execution order' do
      let(:query_string) {%|
        mutation setInOrder {
          first:  pushValue(value: 1)
          second: pushValue(value: 5)
          third:  pushValue(value: 2)
        }
      |}
      it 'executes mutations in order' do
        expected = {"data"=>{
          "setInOrder"=>{
            "first"=> [1],
            "second"=>[1, 5],
            "third"=> [1, 5, 2],
          }
        }}
        assert_equal(expected, result)
      end
    end
  end
end
