require 'spec_helper'

describe GraphQL::Node do
  let(:query_string) { "type(post) { name, description, fields { count, edges { node { name, type }}} }"}
  let(:result) { GraphQL::Query.new(query_string).as_result}

  describe '__type__' do
    let(:title_field) { result["post"]["fields"]["edges"].find {|e| e["node"]["name"] == "title"}["node"] }

    it 'has name' do
      assert_equal "post", result["post"]["name"]
    end

    it 'has description' do
      assert_equal "A blog post entry", result["post"]["description"]
    end

    it 'has fields' do
      assert_equal 8, result["post"]["fields"]["count"]
      assert_equal({ "name" => "title", "type" => "string"}, title_field)
    end

    describe 'getting the __type__ field' do
      before do
        @post = Post.create(id: 155, content: "Hello world")
      end

      after do
        @post.destroy
      end

      let(:query_string) { "post(155) { __type__ { name, fields { count } } }"}

      it 'exposes the type' do
        assert_equal "post", result["155"]["__type__"]["name"]
        assert_equal 8, result["155"]["__type__"]["fields"]["count"]
      end
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
      assert_equal 5, Nodes::CommentNode.all_fields.size
      Nodes::CommentNode.field.number(:id)
      Nodes::CommentNode.field.number(:id)
      assert_equal 5, Nodes::CommentNode.all_fields.size
      Nodes::CommentNode.remove_field(:id)
    end

    describe 'type:' do
      it 'uses symbols to find built-ins' do
        field_mapping = Nodes::CommentNode.all_fields["id"]
        assert_equal GraphQL::Types::NumberType, field_mapping.type_class
      end
      it 'uses the provided class as a superclass' do
        letters_field = Nodes::CommentNode.all_fields["letters"]
        assert_equal Nodes::LetterSelectionType, letters_field.type_class
      end
    end
  end
end
