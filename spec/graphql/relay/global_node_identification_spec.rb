require 'spec_helper'

describe GraphQL::Relay::GlobalNodeIdentification do
  let(:node_identification) { NodeIdentification }
  describe 'NodeField' do
    it 'finds objects by id' do
      global_id = node_identification.to_global_id("Faction", "1")
      result = query(%|{
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

  describe 'to_global_id / from_global_id ' do
    it 'Converts typename and ID to and from ID' do
      global_id = node_identification.to_global_id("SomeType", "123")
      type_name, id = node_identification.from_global_id(global_id)
      assert_equal("SomeType", type_name)
      assert_equal("123", id)
    end
  end

  describe "type_from_object" do
    describe "when the return value is not a BaseType" do
      it "raises an error " do
        err = assert_raises {
          GraphQL::Relay::GlobalNodeIdentification.instance.type_from_object(:test_error)
        }
        assert_includes err.message, "not_a_type (Symbol)"
      end
    end
  end

  describe 'making a second instance' do
    before do
      @first_instance = GraphQL::Relay::GlobalNodeIdentification.instance
    end

    after do
      GraphQL::Relay::GlobalNodeIdentification.instance = @first_instance
    end

    it 'overrides the first instance' do
      GraphQL::Relay::GlobalNodeIdentification.define {}
      second_instance = GraphQL::Relay::GlobalNodeIdentification.instance
      refute_equal(@first_instance, second_instance)
    end
  end
end
