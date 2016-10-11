require 'spec_helper'

describe GraphQL::Relay::Mutation do
  let(:query_string) {%|
    mutation addBagel($clientMutationId: String) {
      introduceShip(input: {shipName: "Bagel", factionId: "1", clientMutationId: $clientMutationId}) {
        clientMutationId
        shipEdge {
          node { name, id }
        }
        faction { name }
      }
    }
  |}
  let(:introspect) {%|
    {
      __schema {
        types { name, fields { name } }
      }
    }
  |}

  after do
    STAR_WARS_DATA["Ship"].delete("9")
    STAR_WARS_DATA["Faction"]["1"]["ships"].delete("9")
  end

  it "returns the result & clientMutationId" do
    result = star_wars_query(query_string, "clientMutationId" => "1234")
    expected = {"data" => {
      "introduceShip" => {
        "clientMutationId" => "1234",
        "shipEdge" => {
          "node" => {
            "name" => "Bagel",
            "id" => GraphQL::Schema::UniqueWithinType.encode("Ship", "9"),
          },
        },
        "faction" => {"name" => STAR_WARS_DATA["Faction"]["1"].name }
      }
    }}
    assert_equal(expected, result)
  end

  it "doesn't require a clientMutationId to perform mutations" do
    result = star_wars_query(query_string)
    new_ship_name = result["data"]["introduceShip"]["shipEdge"]["node"]["name"]
    assert_equal("Bagel", new_ship_name)
  end

  it "applies the description to the derived field" do
    assert_equal "Add a ship to this faction", IntroduceShipMutation.field.description
  end

  it "inserts itself into the derived objects' metadata" do
    assert_equal IntroduceShipMutation, IntroduceShipMutation.field.mutation
    assert_equal IntroduceShipMutation, IntroduceShipMutation.return_type.mutation
    assert_equal IntroduceShipMutation, IntroduceShipMutation.input_type.mutation
    assert_equal IntroduceShipMutation, IntroduceShipMutation.result_class.mutation
  end

  describe "providing a return type" do
    let(:custom_return_type) {
      GraphQL::ObjectType.define do
        name "CustomReturnType"
        field :name, types.String
      end
    }

    let(:mutation) {
      custom_type = custom_return_type
      GraphQL::Relay::Mutation.define do
        name "CustomReturnTypeTest"
        return_type custom_type
      end
    }

    it "uses the provided type" do
      assert_equal custom_return_type, mutation.return_type
      assert_equal custom_return_type, mutation.field.type
    end

    it "doesn't get a mutation in the metadata" do
      assert_equal nil, custom_return_type.mutation
    end
  end
end
