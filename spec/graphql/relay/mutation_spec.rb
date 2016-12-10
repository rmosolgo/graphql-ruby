# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Relay::Mutation do
  let(:query_string) {%|
    mutation addBagel($clientMutationId: String, $shipName: String = "Bagel") {
      introduceShip(input: {shipName: $shipName, factionId: "1", clientMutationId: $clientMutationId}) {
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
    STAR_WARS_DATA["Faction"]["1"].ships.delete("9")
  end

  it "supports null values" do
    result = star_wars_query(query_string, "clientMutationId" => "1234", "shipName" => nil)

    expected = {"data" => {
      "introduceShip" => {
        "clientMutationId" => "1234",
        "shipEdge" => {
          "node" => {
            "name" => nil,
            "id" => GraphQL::Schema::UniqueWithinType.encode("Ship", "9"),
          },
        },
        "faction" => {"name" => STAR_WARS_DATA["Faction"]["1"].name }
      }
    }}
    assert_equal(expected, result)
  end

  it "supports lazy resolution" do
    result = star_wars_query(query_string, "clientMutationId" => "1234", "shipName" => "Slave II")
    assert_equal "Slave II", result["data"]["introduceShip"]["shipEdge"]["node"]["name"]
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

  describe "aliased methods" do
    describe "on an unreached mutation" do
      it 'still ensures definitions' do
        UnreachedMutation = GraphQL::Relay::Mutation.define do
          name 'UnreachedMutation'
          description 'A mutation type not directly used in the schema.'

          input_field :input, types.String
          return_field :return, types.String
        end

        assert UnreachedMutation.input_fields['input']
        assert UnreachedMutation.return_fields['return']
      end
    end
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

        input_field :nullDefault, types.String, default_value: nil
        input_field :noDefault, types.String
        input_field :stringDefault, types.String, default_value: 'String'

        return_type custom_type
        resolve ->(obj, input, ctx) {
          OpenStruct.new(name: "Custom Return Type Test")
        }
      end
    }

    let(:input) { mutation.field.arguments['input'].type.unwrap }

    let(:schema) {
      mutation_field = mutation.field

      mutation_root = GraphQL::ObjectType.define do
        name "Mutation"
        field :custom, mutation_field
      end

      GraphQL::Schema.define do
        mutation(mutation_root)
      end
    }

    it "uses the provided type" do
      assert_equal custom_return_type, mutation.return_type
      assert_equal custom_return_type, mutation.field.type

      result = schema.execute("mutation { custom(input: {}) { name } }")
      assert_equal "Custom Return Type Test", result["data"]["custom"]["name"]
    end

    it "doesn't get a mutation in the metadata" do
      assert_equal nil, custom_return_type.mutation
    end

    it "supports input fields with nil default value" do
      assert input.arguments['nullDefault'].default_value?
      assert_equal nil, input.arguments['nullDefault'].default_value
    end

    it "supports input fields with no default value" do
      assert !input.arguments['noDefault'].default_value?
      assert_equal nil, input.arguments['noDefault'].default_value
    end

    it "supports input fields with non-nil default value" do
      assert input.arguments['stringDefault'].default_value?
      assert_equal "String", input.arguments['stringDefault'].default_value
    end
  end

  describe "handling errors" do
    it "supports returning an error in resolve" do
      result = star_wars_query(query_string, "clientMutationId" => "5678", "shipName" => "Millennium Falcon")

      expected = {
        "data" => {
          "introduceShip" => {
            "clientMutationId" => "5678",
            "shipEdge" => nil,
            "faction" => nil,
          }
        },
        "errors" => [
          {
            "message" => "Sorry, Millennium Falcon ship is reserved",
            "locations" => [ { "line" => 3 , "column" => 7}],
            "path" => ["introduceShip"]
          }
        ]
      }

      assert_equal(expected, result)
    end
  end
end
