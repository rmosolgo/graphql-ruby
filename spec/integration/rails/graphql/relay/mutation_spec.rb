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
    StarWars::DATA["Ship"].delete("9")
    StarWars::DATA["Faction"]["1"].ships.delete("9")
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
        "faction" => {"name" => StarWars::DATA["Faction"]["1"].name }
      }
    }}
    assert_equal(expected, result)
  end

  it "supports lazy resolution" do
    result = star_wars_query(query_string, "clientMutationId" => "1234", "shipName" => "Slave II")
    assert_equal "Slave II", result["data"]["introduceShip"]["shipEdge"]["node"]["name"]
  end

  it "raises when using a generated return type and resolve doesnt return a Hash" do
    bad_mutation = GraphQL::Relay::Mutation.define do
      name 'BadMutation'
      description 'A mutation type that doesnt return a hash'

      input_field :input, types.String
      return_field :return, types.String

      resolve ->(_, _, _) {
        # Should have been { return: 'my_bad_return_value' }
        'my_bad_return_value'
      }
    end

    root = GraphQL::ObjectType.define do
      name "MutationRoot"
      field :bad, bad_mutation.field
    end

    schema = GraphQL::Schema.define { mutation(root) }

    exception = assert_raises(StandardError) do
      schema.execute('mutation { bad(input: { input: "graphql" }) { return } }')
    end

    expected_message = "Expected `my_bad_return_value` to be a Hash."\
      " Return a hash when using `return_field` or specify a custom `return_type`."
    assert_equal expected_message, exception.message
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
        "faction" => {"name" => StarWars::DATA["Faction"]["1"].name }
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
    field = GraphQL::Schema::Field.from_options(name: "x", **StarWars::IntroduceShipMutation.field_options)
    assert_equal "Add a ship to this faction", field.description
  end

  it "inserts itself into the derived objects' metadata" do
    field = GraphQL::Schema::Field.from_options(name: "x", **StarWars::IntroduceShipMutation.field_options)
    assert_equal StarWars::IntroduceShipMutation, field.mutation
    assert_equal StarWars::IntroduceShipMutation, field.to_graphql.mutation
    assert_equal StarWars::IntroduceShipMutation, StarWars::IntroduceShipMutation.payload_type.mutation
    assert_equal StarWars::IntroduceShipMutation, StarWars::IntroduceShipMutation.input_type.mutation
  end

  describe "return_field ... property:" do
    it "resolves correctly" do
      query_str = <<-GRAPHQL
        mutation {
          introduceShip(input: {shipName: "Bagel", factionId: "1"}) {
            aliasedFaction { name }
          }
        }
      GRAPHQL
      result = star_wars_query(query_str)
      faction_name = result["data"]["introduceShip"]["aliasedFaction"]["name"]
      assert_equal("Alliance to Restore the Republic", faction_name)
    end
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
      assert_nil custom_return_type.mutation
    end

    it "supports input fields with nil default value" do
      assert input.arguments['nullDefault'].default_value?
      assert_nil input.arguments['nullDefault'].default_value
    end

    it "supports input fields with no default value" do
      assert !input.arguments['noDefault'].default_value?
      assert_nil input.arguments['noDefault'].default_value
    end

    it "supports input fields with non-nil default value" do
      assert input.arguments['stringDefault'].default_value?
      assert_equal "String", input.arguments['stringDefault'].default_value
    end
  end

  describe "specifying return interfaces" do
    let(:result_interface) {
      GraphQL::InterfaceType.define do
        name "ResultInterface"
        field :success, !types.Boolean
        field :notice, types.String
      end
    }

    let(:error_interface) {
      GraphQL::InterfaceType.define do
        name "ErrorInterface"
        field :error, types.String
      end
    }

    let(:mutation) {
      interfaces = [result_interface, error_interface]
      GraphQL::Relay::Mutation.define do
        name "ReturnTypeWithInterfaceTest"

        return_field :name, types.String

        return_interfaces interfaces

        resolve ->(obj, input, ctx) {
          {
            name: "Type Specific Field",
            success: true,
            notice: "Success Interface Field",
            error: "Error Interface Field"
          }
        }
      end
    }

    let(:schema) {
      mutation_field = mutation.field

      mutation_root = GraphQL::ObjectType.define do
        name "Mutation"
        field :custom, mutation_field
      end

      GraphQL::Schema.define do
        mutation(mutation_root)
        resolve_type NO_OP_RESOLVE_TYPE
      end
    }

    it 'makes the mutation type implement the interfaces' do
      assert_equal [result_interface, error_interface], mutation.return_type.interfaces
    end

    it "returns interface values and specific ones" do
      result = schema.execute('mutation { custom(input: {clientMutationId: "123"}) { name, success, notice, error, clientMutationId } }')
      assert_equal "Type Specific Field", result["data"]["custom"]["name"]
      assert_equal "Success Interface Field", result["data"]["custom"]["notice"]
      assert_equal true, result["data"]["custom"]["success"]
      assert_equal "Error Interface Field", result["data"]["custom"]["error"]
      assert_equal "123", result["data"]["custom"]["clientMutationId"]
    end
  end

  describe "handling errors" do
    it "supports returning an error in resolve" do
      result = star_wars_query(query_string, "clientMutationId" => "5678", "shipName" => "Millennium Falcon")

      expected = {
        "data" => {
          "introduceShip" => nil,
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

    it "supports raising an error in a lazy callback" do
      result = star_wars_query(query_string, "clientMutationId" => "5678", "shipName" => "Ebon Hawk")

      expected = {
        "data" => {
          "introduceShip" => nil,
        },
        "errors" => [
          {
            "message" => "💥",
            "locations" => [ { "line" => 3 , "column" => 7}],
            "path" => ["introduceShip"]
          }
        ]
      }

      assert_equal(expected, result)
    end

    it "supports raising an error in the resolve function" do
      result = star_wars_query(query_string, "clientMutationId" => "5678", "shipName" => "Leviathan")

      expected = {
        "data" => {
          "introduceShip" => nil,
        },
        "errors" => [
          {
            "message" => "🔥",
            "locations" => [ { "line" => 3 , "column" => 7}],
            "path" => ["introduceShip"]
          }
        ]
      }

      assert_equal(expected, result)
    end
  end
end
