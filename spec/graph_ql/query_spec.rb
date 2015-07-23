require 'spec_helper'

describe GraphQL::Query do
  describe '#execute' do
    let(:query_string) { %|
      query getFlavor($cheeseId: Int!) {
        brie: cheese(id: 1)   { ...cheeseFields, taste: flavor },
        cheese(id: $cheeseId)  {
          __typename,
          id,
          ...cheeseFields,
          ... edibleFields,
          ... on Cheese { cheeseKind: flavor },
        }
        fromSource(source: COW) { id }
        firstSheep: searchDairy(product: {source: SHEEP}) { ... dairyFields, ... milkFields }
        favoriteEdible { __typename, fatContent }
      }
      fragment cheeseFields on Cheese { flavor }
      fragment edibleFields on Edible { fatContent }
      fragment milkFields on Milk { source }
      fragment dairyFields on AnimalProduct {
         ... on Cheese { flavor }
         ... on Milk   { source }
      }
    |}
    let(:debug) { false }
    let(:query) { GraphQL::Query.new(DummySchema, query_string, params: {"cheeseId" => 2}, debug: debug)}
    let(:result) { query.result }

    it 'returns fields on objects' do
      expected = {"data"=> {
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
      }}
      assert_equal(expected, result)
    end

    it 'exposes fragments' do
      assert_equal(GraphQL::Nodes::FragmentDefinition, query.fragments['cheeseFields'].class)
    end

    describe 'runtime errors' do
      let(:query_string) {%| query noMilk { error }|}
      describe 'if debug: false' do
        let(:debug) { false }
        it 'turns into error messages' do
          expected = {"errors"=>[
            {"message"=>"Something went wrong during query execution: This error was raised on purpose"}
          ]}
          assert_equal(expected, result)
        end
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
            "first"=> [1],
            "second"=>[1, 5],
            "third"=> [1, 5, 2],
        }}
        assert_equal(expected, result)
      end
    end
  end

  describe 'context' do
    let(:context_field) { GraphQL::Field.new do |f, types, field, args|
      f.type(GraphQL::STRING_TYPE)
      f.arguments(key: args.build(type: types.String))
      f.resolve -> (target, args, ctx) { ctx[args["key"]] }
    end}
    let(:query_type) { GraphQL::ObjectType.new {|t| t.fields({context: context_field})}}
    let(:schema) { GraphQL::Schema.new(query: query_type, mutation: nil)}
    let(:query) { GraphQL::Query.new(schema, query_string, context: {"some_key" => "some value"})}
    let(:query_string) { %|
      query getCtx { context(key: "some_key") }
    |}

    it 'passes context to fields' do
      expected = {"data" => {"context" => "some value"}}
      assert_equal(expected, query.result)
    end
  end
end
