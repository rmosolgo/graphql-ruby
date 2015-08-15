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
        fromSheep: fromSource(source: SHEEP) { id }
        firstSheep: searchDairy(product: {source: SHEEP}) {
          __typename,
          ... dairyFields,
          ... milkFields
        }
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
    let(:operation_name) { nil }
    let(:query) { GraphQL::Query.new(
      DummySchema,
      query_string,
      variables: {"cheeseId" => 2},
      debug: debug,
      operation_name: operation_name,
    )}
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
          "fromSheep"=>[{"id"=>3}],
          "firstSheep" => { "__typename" => "Cheese", "flavor" => "Manchego" },
          "favoriteEdible"=>{"__typename"=>"Milk", "fatContent"=>0.04},
      }}
      assert_equal(expected, result)
    end

    it 'exposes fragments' do
      assert_equal(GraphQL::Language::Nodes::FragmentDefinition, query.fragments['cheeseFields'].class)
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

    describe "malformed queries" do
      describe "whitespace-only" do
        let(:query_string) { " " }
        it "doesn't blow up" do
          assert_equal({"data"=> {}}, result)
        end
      end

      describe "empty string" do
        let(:query_string) { "" }
        it "doesn't blow up" do
          assert_equal({"data"=> {}}, result)
        end
      end
    end

    describe "multiple operations" do
      let(:query_string) { %|
        query getCheese1 { cheese(id: 1) { flavor } }
        query getCheese2 { cheese(id: 2) { flavor } }
      |}
      describe "when an operation is named" do
        let(:operation_name) { "getCheese2" }
        it "runs the named one" do
          expected = {
            "data" => {
              "cheese" => {
                "flavor" => "Gouda"
              }
            }
          }
          assert_equal(expected, result)
        end
      end

      describe "when one is NOT named" do
        it "returns an error" do
          expected = {
            "errors" => [
              {"message" => "You must provide an operation name from: getCheese1, getCheese2"}
            ]
          }
          assert_equal(expected, result)
        end
      end
    end


    describe 'execution order' do
      let(:query_string) {%|
        mutation setInOrder {
          first:  pushValue(value: 1)
          second: pushValue(value: 5)
          third:  pushValue(value: 2)
          fourth: replaceValues(input: {values: [6,5,4]})
        }
      |}

      it 'executes mutations in order' do
        expected = {"data"=>{
            "first"=> [1],
            "second"=>[1, 5],
            "third"=> [1, 5, 2],
            "fourth"=> [6, 5 ,4],
        }}
        assert_equal(expected, result)
      end
    end
  end

  describe 'context' do
    let(:query_type) { GraphQL::ObjectType.define {
      field :context, types.String do
        argument :key, !types.String
        resolve -> (target, args, ctx) { ctx[args[:key]] }
      end
    }}
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
