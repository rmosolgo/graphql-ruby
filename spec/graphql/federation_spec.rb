# frozen_string_literal: true
require "spec_helper"
require "graphql/federation"

describe "GraphQL::Federation" do
  module FederationSpec
    MANUFACTURERS = {
      "1" => { "id" => "1", "name" => "Acme" },
    }.freeze

    PRODUCTS = {
      "1" => { "id" => "1", "manufacturer_id" => "1", "sku" => "table-1", "name" => "Table" },
      "2" => { "id" => "2", "manufacturer_id" => "1", "sku" => "chair-1", "name" => "Chair" },
    }.freeze

    class Manufacturer < GraphQL::Schema::Object
      key "id"

      field :id, ID, null: false
      field :name, String, null: false

      def self.resolve_reference(representation, context:)
        context[:resolved_references] << ["Manufacturer", representation["id"]] if context[:resolved_references]
        MANUFACTURERS[representation["id"]]
      end
    end

    class Product < GraphQL::Schema::Object
      key "id"

      field :id, ID, null: false
      field :manufacturer, Manufacturer, null: true
      field :name, String, null: false

      field :sku, String, null: false do
        external
      end

      field :shipping_estimate, Integer, null: true do
        requires "sku"
      end

      def self.resolve_reference(representation, context:)
        context[:resolved_references] << ["Product", representation["id"]] if context[:resolved_references]
        PRODUCTS[representation["id"]]
      end

      def manufacturer
        MANUFACTURERS[object["manufacturer_id"]]
      end

      def shipping_estimate
        100
      end
    end

    class Query < GraphQL::Schema::Object
      field :product, Product, null: true do
        argument :id, ID, required: true
      end

      def product(id:)
        PRODUCTS[id]
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      use GraphQL::Federation
    end

    class PlainQuery < GraphQL::Schema::Object
      field :hello, String, null: false

      def hello
        "world"
      end
    end

    class PlainSchema < GraphQL::Schema
      query(PlainQuery)
      use GraphQL::Federation
    end
  end

  it "adds federation directives and helper fields to the schema" do
    sdl = FederationSpec::Schema.to_definition

    assert_includes sdl, "directive @key("
    assert_includes sdl, "scalar _Any"
    assert_includes sdl, "scalar _FieldSet"
    assert_includes sdl, "union _Entity = Manufacturer | Product"
    assert_includes sdl, "type _Service"
    assert_includes sdl, "_service: _Service!"
    assert_includes sdl, "_entities(representations: [_Any!]!): [_Entity]!"
    assert_includes sdl, "type Manufacturer @key(fields: \"id\")"
    assert_includes sdl, "type Product @key(fields: \"id\")"
    assert_includes sdl, "sku: String! @external"
    assert_includes sdl, "shippingEstimate: Int @requires(fields: \"sku\")"
  end

  it "omits entity helpers when there are no federated entities" do
    sdl = FederationSpec::PlainSchema.to_definition

    assert_includes sdl, "_service: _Service!"
    refute_includes sdl, "_entities"
    refute_includes sdl, "union _Entity"
  end

  it "exposes _service.sdl" do
    result = FederationSpec::Schema.execute("{ _service { sdl } }").to_h
    sdl = result["data"]["_service"]["sdl"]

    assert_includes sdl, "type Product @key(fields: \"id\")"
    refute_includes sdl, "type _Service"
    refute_includes sdl, "union _Entity"
    refute_includes sdl, "_entities"
    refute_includes sdl, "_service"
  end

  it "resolves multiple federated entity types in one query" do
    resolved_references = []
    result = FederationSpec::Schema.execute(
      <<~GRAPHQL,
        query($representations: [_Any!]!) {
          _entities(representations: $representations) {
            __typename
            ... on Product {
              id
              name
              manufacturer {
                id
                name
              }
            }
            ... on Manufacturer {
              id
              name
            }
          }
        }
      GRAPHQL
      variables: {
        "representations" => [
          { "__typename" => "Product", "id" => "1" },
          { "__typename" => "Manufacturer", "id" => "1" },
        ],
      },
      context: { resolved_references: resolved_references }
    ).to_h

    assert_equal [["Product", "1"], ["Manufacturer", "1"]], resolved_references
    assert_equal [
      { "__typename" => "Product", "id" => "1", "name" => "Table", "manufacturer" => { "id" => "1", "name" => "Acme" } },
      { "__typename" => "Manufacturer", "id" => "1", "name" => "Acme" },
    ], result["data"]["_entities"]
  end
end
