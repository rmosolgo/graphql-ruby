require 'spec_helper'

describe GraphQL::Relay::Node do
  describe 'NodeField' do
    it 'finds objects by id' do
      global_id = GraphQL::Relay::Node.to_global_id("Ship", "1")
      result = query(%|{node(id: "#{global_id}") { id, ... on Ship { name } }}|)
      expected = {"data" => {
        "node" => {
          "id" =>   global_id,
          "name" => "X-Wing"
        }
      }}
      assert_equal(expected, result)
    end
  end

  describe 'to_global_id / from_global_id ' do
    it 'Converts typename and ID to and from ID' do
      global_id = GraphQL::Relay::Node.to_global_id("SomeType", "123")
      type_name, id = GraphQL::Relay::Node.from_global_id(global_id)
      assert_equal("SomeType", type_name)
      assert_equal("123", id)
    end
  end
end
