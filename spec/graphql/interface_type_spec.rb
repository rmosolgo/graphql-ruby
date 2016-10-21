require "spec_helper"

describe GraphQL::InterfaceType do
  let(:interface) { EdibleInterface }
  let(:dummy_query_context) { OpenStruct.new(schema: DummySchema) }

  it "has possible types" do
    assert_equal([CheeseType, HoneyType, MilkType], DummySchema.possible_types(interface))
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

    describe "filtering members by type" do
      let(:query_string) {%|
      {
        allEdible {
          __typename
          ... on LocalProduct {
            origin
          }
        }
      }
      |}

      it "only applies fields to the right object" do
        expected_data = [
          {"__typename"=>"Cheese", "origin"=>"France"},
          {"__typename"=>"Cheese", "origin"=>"Netherlands"},
          {"__typename"=>"Cheese", "origin"=>"Spain"},
          {"__typename"=>"Milk", "origin"=>"Antiquity"},
          {"__typename"=>"Milk", "origin"=>"Modernity"},
        ]

        assert_equal expected_data, result["data"]["allEdible"]
      end
    end
  end
end
