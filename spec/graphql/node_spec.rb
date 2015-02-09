require 'spec_helper'

describe GraphQL::Node do
  let(:query_string) { "type(Post) { name, description, fields.first(1) { count, edges { node { name, description }}} }"}
  let(:result) { GraphQL::Query.new(query_string, namespace: Nodes).as_json }

  describe '__type__' do
    it 'has name' do
      assert_equal "Post", result["Post"]["name"]
    end

    it 'has description' do
      assert_equal "A blog post entry", result["Post"]["description"]
    end

    it 'has fields' do
      assert_equal 6, result["Post"]["fields"]["count"]
      assert_equal 1, result["Post"]["fields"]["edges"].length
      assert_equal({ "name" => "id", "description" => nil}, result["Post"]["fields"]["edges"][0]["node"])
    end

    it 'has edges'
  end

  describe '.node_name' do
    let(:query_string) { "type(Upvote) { name }"}

    it 'overrides __type__.name' do
      assert_equal "Upvote", result["Upvote"]["name"]
    end
  end

  describe '.field' do
    describe 'method:' do
      it 'defaults to field_name'
      it 'can be overriden'
    end

    describe 'extends:' do
      it 'uses the provided class as a superclass' do
        first_letter = Nodes::ThumbUpNode.fields[1]
        assert first_letter.superclass == Nodes::FirstLetterField
      end
    end
  end
end
