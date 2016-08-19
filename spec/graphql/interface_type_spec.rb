require "spec_helper"

describe GraphQL::InterfaceType do
  let(:interface) { EdibleInterface }
  let(:dummy_query_context) { OpenStruct.new(schema: DummySchema) }

  it "has possible types" do
    assert_equal([CheeseType, HoneyType, MilkType], DummySchema.possible_types(interface))
  end

  it "resolves types for objects" do
    assert_equal(CheeseType, interface.resolve_type(CHEESES.values.first, dummy_query_context))
    assert_equal(MilkType, interface.resolve_type(MILKS.values.first, dummy_query_context))
  end

  describe "query evaluation" do
    let(:result) { DummySchema.execute(query_string, variables: {"cheeseId" => 2})}
    let(:query_string) {%|
      query fav {
        favoriteEdible { fatContent }
      }
    |}
    it "gets fields from the type for the given object" do
      expected = {"data"=>{"favoriteEdible"=>{"fatContent"=>0.04}}}
      assert_equal(expected, result)
    end
  end

  describe "mergable query evaluation" do
    let(:result) { DummySchema.execute(query_string, variables: {"cheeseId" => 2})}
    let(:query_string) {%|
      query fav {
        favoriteEdible { fatContent }
        favoriteEdible { origin }
      }
    |}
    it "gets fields from the type for the given object" do
      expected = {"data"=>{"favoriteEdible"=>{"fatContent"=>0.04, "origin"=>"Antiquity"}}}
      assert_equal(expected, result)
    end
  end

  describe '#resolve_type' do
    let(:interface) {
      GraphQL::InterfaceType.define do
        resolve_type -> (object, ctx) {
          :custom_resolve
        }
      end
    }

    it "can be overriden in the definition" do
      assert_equal(interface.resolve_type(123, nil), :custom_resolve)
    end
  end

  describe "fragments" do
    let(:query_string) {%|
    {
      favoriteEdible {
        fatContent
        ... on LocalProduct {
          origin
        }
      }
    }
    |}
    let(:result) { DummySchema.execute(query_string) }

    it "can apply interface fragments to an interface" do
      expected_result = { "data" => {
        "favoriteEdible" => {
          "fatContent" => 0.04,
          "origin" => "Antiquity",
        }
      } }

      assert_equal(expected_result, result)
    end
  end
end
