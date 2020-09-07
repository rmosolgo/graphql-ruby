require "spec_helper"

describe GraphQL::Schema::Member::RelayShortcuts do
  describe 'connection_type' do
    module NonNullAbleConnectionShortcutsDummy
      class Node < GraphQL::Schema::Object
        field :some_field, String, null: true
      end

      class Query < GraphQL::Schema::Object
        field :connection, Node.connection_type(node_nullable: false), null: false
      end

      class Schema < GraphQL::Schema
        query Query
      end
    end

    it "node_nullable option is works" do
      res = NonNullAbleConnectionShortcutsDummy::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      edge_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "NodeConnection" }
      nodes_field = edge_type["fields"].find { |f| f["name"] == "nodes" }
      assert_equal "NON_NULL",nodes_field["type"]["kind"]
      assert_equal "NON_NULL",nodes_field["type"]["ofType"]["ofType"]["kind"]
    end
  end
end

