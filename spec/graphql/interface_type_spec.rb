# frozen_string_literal: true
require "spec_helper"

describe GraphQL::InterfaceType do
  let(:interface) { Dummy::EdibleInterface }
  let(:dummy_query_context) { OpenStruct.new(schema: Dummy::Schema) }

  it "has possible types" do
    assert_equal([Dummy::CheeseType, Dummy::HoneyType, Dummy::MilkType], Dummy::Schema.possible_types(interface))
  end

  describe "query evaluation" do
    let(:result) { Dummy::Schema.execute(query_string, variables: {"cheeseId" => 2})}
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
    let(:result) { Dummy::Schema.execute(query_string, variables: {"cheeseId" => 2})}
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
    let(:result) { Dummy::Schema.execute(query_string) }

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
        ]

        assert_equal expected_data, result["data"]["allEdible"]
      end
    end
  end

  describe "#dup" do
    it "copies the fields without altering the original" do
      interface_2 = interface.dup
      interface_2.fields["extra"] = GraphQL::Field.define(name: "extra", type: GraphQL::BOOLEAN_TYPE)
      assert_equal 3, interface.fields.size
      assert_equal 4, interface_2.fields.size
    end
  end
end
