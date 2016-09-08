require 'spec_helper'

describe GraphQL::Relay::GlobalNodeIdentification do
  let(:node_identification) { StarWarsSchema.node_identification }
  describe 'NodeField' do
    it 'finds objects by id' do
      global_id = node_identification.to_global_id("Faction", "1")
      result = star_wars_query(%|{
        node(id: "#{global_id}") {
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

  after do
    # Set the id_separator back to it's default after each spec, since some of
    # them change it at runtime
    GraphQL::Relay::GlobalNodeIdentification.id_separator = "-"
  end

  describe 'id_separator' do
    it "allows you to change it at runtime" do
      GraphQL::Relay::GlobalNodeIdentification.id_separator = "-zomg-"

      assert_equal("-zomg-", GraphQL::Relay::GlobalNodeIdentification.id_separator)
    end
  end

  describe "type_from_object" do
    it "works even though it's deprecated" do
      thing_type = GraphQL::ObjectType.define do
        name "Thing"
        global_id_field :id
        field :object_id, types.Int
      end

      node_ident = GraphQL::Relay::GlobalNodeIdentification.define do
        type_from_object -> (obj) { thing_type }
      end

      schema = GraphQL::Schema.define do
        node_identification(node_ident)
      end

      schema.send(:ensure_defined)
      assert_equal thing_type, node_ident.type_from_object(nil)
      assert_equal thing_type, schema.resolve_type(nil, nil)
    end
  end

  describe 'to_global_id / from_global_id ' do
    it 'Converts typename and ID to and from ID' do
      global_id = node_identification.to_global_id("SomeType", 123)
      type_name, id = node_identification.from_global_id(global_id)
      assert_equal("SomeType", type_name)
      assert_equal("123", id)
    end

    it "allows you to change the id_separator" do
      GraphQL::Relay::GlobalNodeIdentification.id_separator = "---"

      global_id = node_identification.to_global_id("Type-With-UUID", "250cda0e-a89d-41cf-99e1-2872d89f1100")
      type_name, id = node_identification.from_global_id(global_id)
      assert_equal("Type-With-UUID", type_name)
      assert_equal("250cda0e-a89d-41cf-99e1-2872d89f1100", id)
    end

    it "raises an error if you try and use a reserved character in the ID" do
      err = assert_raises(RuntimeError) {
        node_identification.to_global_id("Best-Thing", "234")
      }
      assert_includes err.message, "to_global_id(Best-Thing, 234) contains reserved characters `-`"
    end

    describe "custom definitions" do
      let(:custom_node_identification) {
        ident = GraphQL::Relay::GlobalNodeIdentification.define do
          to_global_id -> (type_name, id) {
            "#{type_name}/#{id}"
          }

          from_global_id -> (global_id) {
            global_id.split("/")
          }

          object_from_id -> (node_id, ctx) do
            type_name, id = ident.from_global_id(node_id)
            STAR_WARS_DATA[type_name][id]
          end

          description "Hello, World!"
        end
      }

      before do
        @prev_node_identification = StarWarsSchema.node_identification
        StarWarsSchema.node_identification = custom_node_identification
      end

      after do
        StarWarsSchema.node_identification = @prev_node_identification
      end

      describe "generating IDs" do
        it "Applies custom-defined ID generation" do
          result = star_wars_query(%| { largestBase { id } }|)
          generated_id = result["data"]["largestBase"]["id"]
          assert_equal "Base/3", generated_id
        end
      end

      describe "fetching by ID" do
        it "Deconstructs the ID by the custom proc" do
          result = star_wars_query(%| { node(id: "Base/1") { ... on Base { name } } }|)
          base_name = result["data"]["node"]["name"]
          assert_equal "Yavin", base_name
        end
      end

      describe "setting a description" do
        it "allows you to set a description" do
          assert_equal "Hello, World!", custom_node_identification.field.description
        end
      end
    end
  end
end
