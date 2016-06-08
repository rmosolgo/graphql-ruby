require 'spec_helper'

describe GraphQL::Relay::Mutation do
  let(:query_string) {%|
    mutation addBagel($clientMutationId: String) {
      introduceShip(input: {shipName: "Bagel", factionId: "1", clientMutationId: $clientMutationId}) {
        clientMutationId
        ship { name, id }
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
    result = query(query_string, "clientMutationId" => "1234")
    expected = {"data" => {
      "introduceShip" => {
        "clientMutationId" => "1234",
        "ship" => {
          "name" => "Bagel",
          "id" => NodeIdentification.to_global_id("Ship", "9"),
        },
        "faction" => {"name" => STAR_WARS_DATA["Faction"]["1"].name }
      }
    }}
    assert_equal(expected, result)
  end

  it "doesn't require a clientMutationId to perform mutations" do
    result = query(query_string)
    expected = {"data" => {
      "introduceShip" => {
        "clientMutationId" => nil,
        "ship" => {
          "name" => "Bagel",
          "id" => NodeIdentification.to_global_id("Ship", "9"),
        },
        "faction" => {"name" => STAR_WARS_DATA["Faction"]["1"].name }
      }
    }}
    assert_equal(expected, result)
  end
end
