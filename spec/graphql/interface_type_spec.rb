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

    it "copies orphan types without affecting the original" do
      interface = GraphQL::InterfaceType.define do
        name "AInterface"
        orphan_types [Dummy::HoneyType]
      end

      interface_2 = interface.dup
      interface_2.orphan_types << Dummy::CheeseType
      assert_equal 1, interface.orphan_types.size
      assert_equal 2, interface_2.orphan_types.size
    end
  end

  describe "#resolve_type" do
    let(:result) { Dummy::Schema.execute(query_string) }
    let(:query_string) {%|
      {
        allEdible {
          __typename
          ... on Milk {
            milkFatContent: fatContent
          }
          ... on Cheese {
            cheeseFatContent: fatContent
          }
        }

        allEdibleAsMilk {
          __typename
          ... on Milk {
            fatContent
          }
        }
      }
    |}

    it 'returns correct types for general schema and specific interface' do
      expected_result = {
        # Uses schema-level resolve_type
        "allEdible"=>[
          {"__typename"=>"Cheese", "cheeseFatContent"=>0.19},
          {"__typename"=>"Cheese", "cheeseFatContent"=>0.3},
          {"__typename"=>"Cheese", "cheeseFatContent"=>0.065},
          {"__typename"=>"Milk", "milkFatContent"=>0.04}
        ],
        # Uses type-level resolve_type
        "allEdibleAsMilk"=>[
          {"__typename"=>"Milk", "fatContent"=>0.19},
          {"__typename"=>"Milk", "fatContent"=>0.3},
          {"__typename"=>"Milk", "fatContent"=>0.065},
          {"__typename"=>"Milk", "fatContent"=>0.04}
        ]
      }
      assert_equal expected_result, result["data"]
    end
  end

  describe "#get_possible_type" do
    let(:query_string) {%|
      query fav {
        favoriteEdible { fatContent }
      }
    |}

    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string) }

    it "returns the type definition if the type exists and is a possible type of the interface" do
      assert interface.get_possible_type("Cheese", query.context)
    end

    it "returns nil if the type is not found in the schema" do
      assert_nil interface.get_possible_type("Foo", query.context)
    end

    it "returns nil if the type is not a possible type of the interface" do
      assert_nil interface.get_possible_type("Beverage", query.context)
    end
  end

  describe "#possible_type?" do
    let(:query_string) {%|
      query fav {
        favoriteEdible { fatContent }
      }
    |}

    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string) }

    it "returns true if the type exists and is a possible type of the interface" do
      assert interface.possible_type?("Cheese", query.context)
    end

    it "returns false if the type is not found in the schema" do
      refute interface.possible_type?("Foo", query.context)
    end

    it "returns false if the type is not a possible type of the interface" do
      refute interface.possible_type?("Beverage", query.context)
    end
  end
end
