require 'spec_helper'

describe GraphQL::TestCall do
  let(:call_test) { Nodes::LikePostCall.test }

  it 'comes from RootCall.test' do
    assert_instance_of GraphQL::TestCall, call_test
  end


  describe '#execute' do
    before do
      @post = Post.create(id: 221, title: "Something interesting")
      @post.likes.map(&:destroy)
    end

    after do
      @post.likes.map(&:destroy)
      @post.destroy
    end

    it 'executes with those arguments' do
      assert_equal 0, @post.likes.count
      call_test.execute({"id" => 221}, 21)
      assert_equal 1, @post.likes.count
    end

    it 'returns the whole, unwrapped result' do
      result = call_test.execute({"id" => 221}, 41)
      assert_equal([:post, :upvote, :context], result.keys)
      assert_equal(@post, result[:post])
      assert_instance_of(Like, result[:upvote])
      assert_equal(nil, result[:context])
    end

    it 'raises an error with the wrong arguments' do
      assert_equal 0, @post.likes.count
      assert_raises(GraphQL::RootCallArgumentError) { call_test.execute({"id" => 221}, "ABC") }
      assert_equal 0, @post.likes.count
    end
  end

  describe '#with_context' do
    it 'returns a new TestCall with that context' do
      # same call, different context:
      new_test_1 = call_test.with_context("Turnips")
      new_test_2 = call_test.with_context("Carrots")
      result_1 = new_test_1.execute({"id" => 221}, 41)
      result_2 = new_test_2.execute({"id" => 221}, 41)
      assert_equal("Turnips",  result_1[:context])
      assert_equal("Carrots",   result_2[:context])
    end
  end

  describe '#with_arguments' do
    it 'chains with arguments' do
      # same call, different arguments:
      new_test_1 = call_test.with_arguments({"id" => 221}, 141)
      new_test_2 = call_test.with_arguments({"id" => 221}, 292)
      result_1 = new_test_1.execute
      result_2 = new_test_2.execute
      assert_equal(141, result_1[:upvote].person_id)
      assert_equal(292, result_2[:upvote].person_id)
    end

    it 'works with #with_context' do
      # different combinations of args and context:
      new_test_1 = call_test.with_arguments({"id" => 221}, 141)
      new_test_2 = call_test.with_arguments({"id" => 221}, 292)
      new_test_3 = new_test_1.with_context("Turnips")
      new_test_4 = new_test_2.with_context("Carrots")
      new_test_5 = new_test_3.with_arguments({"id" => 221}, 313)

      result_1 = new_test_1.execute
      result_2 = new_test_2.execute
      result_3 = new_test_3.execute
      result_4 = new_test_4.execute
      result_5 = new_test_5.execute

      # Test args:
      assert_equal(141, result_1[:upvote].person_id)
      assert_equal(292, result_2[:upvote].person_id)
      assert_equal(141, result_3[:upvote].person_id)
      assert_equal(292, result_4[:upvote].person_id)
      assert_equal(313, result_5[:upvote].person_id)
      # Test context:
      assert_equal(nil,       result_1[:context])
      assert_equal(nil,       result_2[:context])
      assert_equal("Turnips", result_3[:context])
      assert_equal("Carrots", result_4[:context])
      assert_equal("Turnips", result_5[:context])
    end
  end
end