require 'spec_helper'

describe GraphQL::RootCall do
  let(:query_string) { %{
    upvote_post(<upvote_data>) {
      post {
        likes { count, any }
      }
      upvote {
        post_id
      }
    }
    <upvote_data>: {
      "post" : { "id" : #{@post_id} },
      "person": { "id" : 888 }
    }
  }}
  let(:result) { GraphQL::Query.new(query_string, namespace: Nodes).as_json }

  before do
    # make sure tests don't conflict :(
    @post_id = "#{Time.now.to_i}#{[1,2,3].sample}".to_i
    @post = Post.create(id: @post_id, content: "My great post")
    @like = Like.create(post_id: @post_id)
  end

  after do
    @post.likes.map(&:destroy)
    @post.destroy
  end

  describe '#as_result' do
    it 'operates on the application' do
      assert_equal 1, @post.likes.count
      result
      assert_equal 2, @post.likes.count
    end

    it 'returns fields for the node' do
      assert_equal @post_id, result["upvote"]["post_id"]
      assert_equal 2, result["post"]["likes"]["count"]
      assert_equal true, result["post"]["likes"]["any"]
    end

    it 'validates the input'
  end

  describe '#__type__' do
    it 'describes the input'
    it 'describes the response'
  end
end