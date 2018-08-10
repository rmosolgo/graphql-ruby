# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::RangeAdd do
  # Make sure that the encoder is found through `ctx.schema`:
  module PassThroughEncoder
    def self.encode(plaintext, nonce: false)
      "__#{plaintext}"
    end

    def self.decode(ciphertext, nonce: false)
      ciphertext[2..-1]
    end
  end

  let(:schema) {
    menus = [
      OpenStruct.new(
        name: "Los Primos",
        items: [
          OpenStruct.new(name: "California Burrito", price: 699),
          OpenStruct.new(name: "Fish Taco", price: 399),
        ]
      )
    ]

    item = GraphQL::ObjectType.define do
      name "Item"
      field :price, !types.Int
      field :name, !types.String
    end
    menu = GraphQL::ObjectType.define do
      name "Menu"
      field :name, !types.String
      field :items, !item.connection_type
    end
    query = GraphQL::ObjectType.define do
      name "Query"
      field :menus, types[menu], resolve: Proc.new { menus }
    end
    add_item = GraphQL::Relay::Mutation.define do
      name "AddItem"
      input_field :name, !types.String
      input_field :price, !types.Int
      input_field :menu_idx, !types.Int

      return_field :item_edge, item.edge_type
      return_field :items, item.connection_type
      return_field :menu, menu
      resolve ->(obj, input, ctx) {
        this_menu = menus[input[:menu_idx]]
        new_item = OpenStruct.new(name: input[:name], price: input[:price])
        this_menu.items << new_item
        range_add = GraphQL::Relay::RangeAdd.new(
          parent: this_menu,
          item: new_item,
          collection: this_menu.items,
          context: ctx,
        )

        {
          menu: range_add.parent,
          items: range_add.connection,
          item_edge: range_add.edge,
        }
      }
    end
    mutation = GraphQL::ObjectType.define do
      name "Mutation"
      field :add_item, add_item.field
    end

    Class.new(GraphQL::Schema) do
      self.query(query)
      self.mutation(mutation)
      self.cursor_encoder(PassThroughEncoder)
    end
  }


  describe "returning Relay objects" do
    let(:query_str) { <<-GRAPHQL
    mutation {
      add_item(input: {name: "Chilaquiles", price: 699, menu_idx: 0}) {
        menu {
          name
        }
        item_edge {
          node {
            name
            price
          }
        }
        items {
          edges {
            node {
              name
            }
            cursor
          }
        }
      }
    }
    GRAPHQL
    }

    it "returns a connection and an edge" do
      res = schema.execute(query_str)

      mutation_res = res["data"]["add_item"]
      assert_equal("Los Primos", mutation_res["menu"]["name"])
      assert_equal({"name"=>"Chilaquiles", "price"=>699}, mutation_res["item_edge"]["node"])
      assert_equal(["California Burrito", "Fish Taco", "Chilaquiles"], mutation_res["items"]["edges"].map { |e| e["node"]["name"] })
      assert_equal(["__1", "__2", "__3"], mutation_res["items"]["edges"].map { |e| e["cursor"] })
    end
  end
end
