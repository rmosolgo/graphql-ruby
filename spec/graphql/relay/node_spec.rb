# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::Node do
  describe ".interface" do
    it "is a default relay type" do
      assert_equal true, GraphQL::Relay::Node.interface.default_relay?
    end
  end

  describe ".field" do
    describe "with custom definition" do
      it 'creates a field with the custom definition' do
        faction = StarWars::DATA['Faction'][0]

        node_field = GraphQL::Relay::Node.field do
          name "nod3"
          description "The Relay Node Field"
          resolve ->(_, _ , _) { faction }
        end

        assert_equal "nod3", node_field.name
        assert_equal "The Relay Node Field", node_field.description
        assert_equal faction, node_field.resolve(nil, { 'id' => '1' }, nil)
      end

      it "executes the custom resolve instead of relay default" do
        id = "resolver_is_hardcoded_so_this_does_not_matter"

        result = star_wars_query(%|{
          nodeWithCustomResolver(id: "#{id}") {
            id,
            ... on Faction {
              name
              ships(first: 1) {
                edges {
                 node {
                   name
                   }
                }
              }
            }
          }
        }|)

        expected = {"data" => {
          "nodeWithCustomResolver"=>{
            "id"=>"RmFjdGlvbi0x",
            "name"=>"Alliance to Restore the Republic",
            "ships"=>{
              "edges"=>[
                {"node"=>{
                    "name" => "X-Wing"
                  }
                }
              ]
            }
          }
        }}

        assert_equal(expected, result)
      end
    end

    describe "Custom global IDs" do
      before do
        # TODO: make the schema eager-load so we can remove this
        # Ensure the schema is defined:
        StarWars::Schema.types

        @previous_id_from_object_proc = StarWars::Schema.id_from_object_proc
        @previous_object_from_id_proc = StarWars::Schema.object_from_id_proc

        StarWars::Schema.id_from_object = ->(obj, type_name, ctx) {
          "#{type_name}/#{obj.id}"
        }

        StarWars::Schema.object_from_id = ->(global_id, ctx) {
          type_name, id = global_id.split("/")
          StarWars::DATA[type_name][id]
        }
      end

      after do
        StarWars::Schema.id_from_object = @previous_id_from_object_proc
        StarWars::Schema.object_from_id = @previous_object_from_id_proc
      end

      it "Deconstructs the ID by the custom proc" do
        result = star_wars_query(%| { node(id: "Base/1") { ... on Base { name } } }|)
        base_name = result["data"]["node"]["name"]
        assert_equal "Yavin", base_name
      end

      describe "generating IDs" do
        it "Applies custom-defined ID generation" do
          result = star_wars_query(%| { largestBase { id } }|)
          generated_id = result["data"]["largestBase"]["id"]
          assert_equal "Base/3", generated_id
        end
      end
    end

    describe "setting a description" do
      it "allows you to set a description" do
        node_field = GraphQL::Relay::Node.field
        node_field.description = "Hello, World!"
        assert_equal "Hello, World!", node_field.description
      end
    end

    it 'finds objects by id' do
      id = GraphQL::Schema::UniqueWithinType.encode("Faction", "1")
      result = star_wars_query(%|{
        node(id: "#{id}") {
          id,
          ... on Faction {
            name
            ships(first: 1) {
              edges {
               node {
                 name
                 }
              }
            }
          }
        }
      }|)
      expected = {"data" => {
        "node"=>{
          "id"=>"RmFjdGlvbi0x",
          "name"=>"Alliance to Restore the Republic",
          "ships"=>{
            "edges"=>[
              {"node"=>{
                  "name" => "X-Wing"
                }
              }
            ]
          }
        }
      }}
      assert_equal(expected, result)
    end
  end

  describe ".plural_identifying_field" do
    describe "with custom definition" do
      it 'creates a field with the custom definition' do
        factions = StarWars::DATA['Faction']

        node_field = GraphQL::Relay::Node.plural_field do
          name "nodez"
          description "The Relay Nodes Field"
          resolve ->(_, _ , _) { factions }
        end

        assert_equal "nodez", node_field.name
        assert_equal "The Relay Nodes Field", node_field.description
        assert_equal factions, node_field.resolve_proc.call(nil, { 'ids' => ['1', '2'] }, nil)
      end

      it "executes the custom resolve instead of relay default" do
        id = ["resolver_is_hardcoded_so_this_does_not_matter", "another_id"]

        result = star_wars_query(%|{
          nodesWithCustomResolver(ids: ["#{id[0]}", "#{id[1]}"]) {
            id,
            ... on Faction {
              name
              ships(first: 1) {
                edges {
                 node {
                   name
                   }
                }
              }
            }
          }
        }|)

        expected = {
          "data" => {
            "nodesWithCustomResolver" => [
              {
                "id" => "RmFjdGlvbi0x",
                "name" => "Alliance to Restore the Republic",
                "ships" => {
                  "edges"=>[
                    { "node" => { "name" => "X-Wing" } }
                  ]
                }
              },
              {
                "id" => "RmFjdGlvbi0y",
                "name" => "Galactic Empire",
                "ships" => {
                  "edges"=>[
                    { "node" => { "name" => "TIE Fighter" } }
                  ]
                }
              },
            ]
          }
        }

        assert_equal(expected, result)
      end
    end

    it 'finds objects by ids' do
      id = GraphQL::Schema::UniqueWithinType.encode("Faction", "1")
      id2 = GraphQL::Schema::UniqueWithinType.encode("Faction", "2")

      result = star_wars_query(%|{
        nodes(ids: ["#{id}", "#{id2}"]) {
          id,
          ... on Faction {
            name
            ships(first: 1) {
              edges {
               node {
                 name
                 }
              }
            }
          }
        }
      }|)

      expected = {
        "data" => {
          "nodes" => [{
            "id"=>"RmFjdGlvbi0x",
            "name"=>"Alliance to Restore the Republic",
            "ships"=>{
              "edges"=>[
                {"node"=>{
                    "name" => "X-Wing"
                  }
                }
              ]
            }
          }, {
            "id" => "RmFjdGlvbi0y",
            "name" => "Galactic Empire",
            "ships" => {
              "edges" => [
                { "node" => { "name" => "TIE Fighter" } }
              ]
            }
          }]
        }
      }

      assert_equal(expected, result)
    end

    it 'is marked as relay_nodes_field' do
      assert GraphQL::Relay::Node.plural_field.relay_nodes_field
    end
  end
end
