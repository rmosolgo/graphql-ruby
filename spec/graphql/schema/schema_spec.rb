require 'spec_helper'

describe GraphQL::Schema::Schema do
  let(:schema) { GraphQL::SCHEMA }
  describe 'global instance' do
    it 'exists as GraphQL::SCHEMA' do
      assert GraphQL::SCHEMA.is_a?(GraphQL::Schema::Schema)
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

  describe '#get_type' do
    it 'finds nodes from their class name' do
      assert_equal Nodes::PostNode, schema.get_type("post")
    end

    it 'finds nodes from declared names' do
      assert_equal Nodes::ThumbUpNode, schema.get_type("upvote")
    end
  end

  describe 'querying schema' do
    let(:query_string) { }
    let(:query) { GraphQL::Query.new(query_string) }
    let(:result) { GraphQL::SCHEMA.all }

    describe 'querying calls' do
      let(:upvote_post_call) { result["schema"]["calls"]["edges"].find {|e| e["node"]["name"] == "upvote_post"} }

      it 'returns all calls' do
        assert_equal 7, result["schema"]["calls"]["count"]
      end

      it 'doesnt show abstract call classes' do
        call_names = result["schema"]["calls"]["edges"].map {|e| e["node"]["name"] }
        assert(!call_names.include?("find"))
      end

      it 'shows return types' do
        assert_equal ["post", "upvote"], upvote_post_call["node"]["returns"]
      end

      it 'shows argument types' do
        expected_arguments = [{"node"=>{"name"=>"post_data", "type"=>"object"}}, {"node"=>{"name"=>"person_id", "type"=>"number"}}]
        assert_equal expected_arguments, upvote_post_call["node"]["arguments"]["edges"]
      end
    end

    describe 'querying types' do
      let(:post_type) { result["schema"]["types"]["edges"].find { |e| e["node"]["name"] == "post" }["node"]}
      let(:content_field) { post_type["fields"]["edges"].find { |e| e["node"]["name"] == "content" }["node"]}
      let(:select_call) { content_field["calls"]["edges"].find { |e| e["node"]["name"] == "select"}["node"]}
      let(:type_names) { result["schema"]["types"]["edges"].map {|t| t["node"]["name"] }}

      it 'returns all types' do
        types_count = 19
        assert_equal types_count, result["schema"]["types"]["count"]
        assert_equal types_count, type_names.length
      end

      it 'doesnt return types that dont expose anything' do
        type_names = result["schema"]["types"]["edges"].map {|e| e["node"]["name"] }
        assert(!type_names.include?("application"))
      end

      it 'show type name & fields' do
        assert_equal "post", post_type["name"]
        assert_equal 8, post_type["fields"]["count"]
      end

      it 'has custom types' do
        assert type_names.include?("letter_selection")
        assert_equal "letter_selection", content_field["type"]
      end

      it 'shows field type & calls' do
        assert_equal "letter_selection", content_field["type"]
        assert_equal 3, content_field["calls"]["count"]
        assert_equal "select", select_call["name"]
        assert_equal "from_chars (req), for_chars (req)", select_call["arguments"]
      end
    end
  end
end