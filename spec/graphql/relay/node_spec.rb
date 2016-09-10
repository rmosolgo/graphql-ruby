require "spec_helper"

describe GraphQL::Relay::Node do
  describe ".field" do
    describe "Custom global IDs" do
      before do
        @previous_to_global_id = StarWarsSchema.to_global_id_proc
        @previous_from_global_id = StarWarsSchema.from_global_id_proc

        StarWarsSchema.to_global_id = -> (type_name, id) {
          "#{type_name}/#{id}"
        }

        StarWarsSchema.from_global_id = -> (global_id) {
          global_id.split("/")
        }
      end

      after do
        StarWarsSchema.to_global_id = @previous_to_global_id
        StarWarsSchema.from_global_id = @previous_from_global_id
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
      global_id = StarWarsSchema.to_global_id("Faction", "1")
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
end
