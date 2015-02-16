require 'spec_helper'

describe GraphQL::Node do
  let(:query_string) { "type(post) { name, description, fields { count, edges { node { name, description }}} }"}
  let(:result) { GraphQL::Query.new(query_string, namespace: Nodes).as_json }

  describe '__type__' do
    let(:title_field) { result["post"]["fields"]["edges"].find {|e| e["node"]["name"] == "title"}["node"] }
    it 'has name' do
      assert_equal "post", result["post"]["name"]
    end

    it 'has description' do
      assert_equal "A blog post entry", result["post"]["description"]
    end

    it 'has fields' do
      assert_equal 7, result["post"]["fields"]["count"]
      assert_equal({ "name" => "title", "description" => nil}, title_field)
    end
  end

  describe '.node_name' do
    let(:query_string) { "type(upvote) { name }"}

    it 'overrides __type__.name' do
      assert_equal "upvote", result["upvote"]["name"]
    end
  end

  describe '.field' do
    it 'doesnt add the field twice if you call it twice' do
      assert_equal 3, Nodes::CommentNode.fields.size
      Nodes::CommentNode.field(:id)
      Nodes::CommentNode.field(:id)
      assert_equal 3, Nodes::CommentNode.fields.size
      Nodes::CommentNode.remove_field(:id)
    end

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
