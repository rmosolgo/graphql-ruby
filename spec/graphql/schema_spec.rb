require 'spec_helper'

describe GraphQL::Schema do
  let(:schema) { GraphQL::SCHEMA }
  describe 'global instance' do
    it 'exists as GraphQL::SCHEMA' do
      assert GraphQL::SCHEMA.is_a?(GraphQL::Schema)
    end
  end

  describe '#get_call' do
    it 'finds calls from their class name' do
      assert_equal Nodes::ContextCall, schema.get_call("context")
    end

    it 'finds calls from declared names' do
      assert_equal Nodes::LikePostCall, schema.get_call("upvote_post")
    end
  end

  describe '#get_node' do
    it 'finds nodes from their class name' do
      assert_equal Nodes::PostNode, schema.get_node("post")
    end

    it 'finds nodes from declared names' do
      assert_equal Nodes::ThumbUpNode, schema.get_node("upvote")
    end
  end

  describe 'querying schema' do
  let(:query_string) { "schema() { calls { count }, nodes { count } } "}
  let(:context) { {person_name: "Han Solo" }}
  let(:query) { GraphQL::Query.new(query_string, namespace: Nodes, context: context) }
  let(:result) { query.as_result }

    it 'returns all calls' do
      assert schema.calls.size > 0
      assert_equal schema.calls.size, result["schema"]["calls"]["count"]
    end

    it 'returns all nodes' do
      assert schema.nodes.size > 0
      assert_equal schema.nodes.size, result["schema"]["nodes"]["count"]
    end
  end
end