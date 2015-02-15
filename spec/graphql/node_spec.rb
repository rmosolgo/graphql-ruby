require 'spec_helper'

describe GraphQL::Node do
  let(:query_string) { "type(post) { name, description, fields { count, edges { node { name, description }}} }"}
  let(:result) { GraphQL::Query.new(query_string, namespace: Nodes).as_json }

  describe '__type__' do
    it 'has name' do
      assert_equal "post", result["post"]["name"]
    end

    it 'has description' do
      assert_equal "A blog post entry", result["post"]["description"]
    end

    it 'has fields' do
      assert_equal 7, result["post"]["fields"]["count"]
      assert_equal({ "name" => "title", "description" => nil}, result["post"]["fields"]["edges"][0]["node"])
    end
  end

  describe '.node_name' do
    let(:query_string) { "type(upvote) { name }"}

    it 'overrides __type__.name' do
      assert_equal "upvote", result["upvote"]["name"]
    end
  end

  describe '.field' do
    describe 'method:' do
      it 'defaults to field_name'
      it 'can be overriden'
    end

    describe 'type:' do
      it 'uses symbols to find built-ins' do
        id_field = Nodes::CommentNode.find_field("id")
        assert id_field.superclass == GraphQL::Types::NumberField
      end
      it 'uses the provided class as a superclass' do
        letters_field = Nodes::CommentNode.find_field("letters")
        assert letters_field.superclass == Nodes::LetterSelectionField
      end
    end
  end
end
