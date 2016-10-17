require "spec_helper"

describe GraphQL::Relay::Node do
  describe ".field" do
    describe "Custom global IDs" do
      before do
        # TODO: make the schema eager-load so we can remove this
        # Ensure the schema is defined:
        StarWarsSchema.types

        @previous_id_from_object_proc = StarWarsSchema.id_from_object_proc
        @previous_object_from_id_proc = StarWarsSchema.object_from_id_proc

        StarWarsSchema.id_from_object = ->(obj, type_name, ctx) {
          "#{type_name}/#{obj.id}"
        }

        StarWarsSchema.object_from_id = ->(global_id, ctx) {
          type_name, id = global_id.split("/")
          STAR_WARS_DATA[type_name][id]
        }
      end

      after do
        StarWarsSchema.id_from_object = @previous_id_from_object_proc
        StarWarsSchema.object_from_id = @previous_object_from_id_proc
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
end
