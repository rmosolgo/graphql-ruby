require 'spec_helper'

describe GraphQL::Query do
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
  describe '#result' do
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

    describe "when it hits null objects" do
      let(:query_string) {%|
        {
          maybeNull {
            cheese {
              flavor,
              similarCheeses(source: [SHEEP]) { flavor }
            }
          }
        }
      |}

      it "skips null objects" do
        expected = {"data"=> {
          "maybeNull" => { "cheese" => nil }
        }}
        assert_equal(expected, result)
      end
    end
  end

  it 'exposes fragments' do
    assert_equal(GraphQL::Language::Nodes::FragmentDefinition, query.fragments['cheeseFields'].class)
  end

  describe "merging fragments with different keys" do
    let(:query_string) { %|
      query getCheeseFieldsThroughDairy {
        dairy {
          ...flavorFragment
          ...fatContentFragment
        }
      }
      fragment flavorFragment on Dairy {
        cheese {
          flavor
        }
        milks {
          id
        }
      }

      fragment fatContentFragment on Dairy {
        cheese {
          fatContent
        }
        milks {
          fatContent
        }
      }

    |}

    it "should include keys from each fragment" do
      expected = {"data" => {
        "dairy" => {
          "cheese" => {
            "flavor" => "Brie",
            "fatContent" => 0.19
          },
          "milks" => [
            {
              "id" => "1",
              "fatContent" => 0.04,
            }
          ],
        }
      }}
      assert_equal(expected, result)
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
