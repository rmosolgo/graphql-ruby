require 'spec_helper'

describe GraphQL::Relay::Mutation do
  let(:query_string) {%|
    mutation addBagel {
      introduceShip(input: {shipName: "Bagel", factionId: "1", clientMutationId: "1234"}) {
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

  it "returns the result & clientMutationId" do
    result = query(query_string)
    expected = {"data" => {
      "introduceShip" => {
        "clientMutationId" => "1234",
        "ship" => {
          "name" => "Bagel",
          "id" => GraphQL::Relay::Node.to_global_id("Ship", "9"),
        },
        "faction" => {"name" => STAR_WARS_DATA["Faction"]["1"].name }
      }
    }}
    assert_equal(expected, result)
    # Cleanup:
    STAR_WARS_DATA["Ship"].delete("9")
    STAR_WARS_DATA["Faction"]["1"]["ships"].delete("9")
  end
end
