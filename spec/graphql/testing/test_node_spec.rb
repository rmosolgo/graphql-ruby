require 'spec_helper'

describe GraphQL::TestNode do
  let(:date) { Date.new(2009,1,10) }
  let(:type_class) { GraphQL::Types::DateTimeType }
  let(:date_test_node) { type_class.test(date) }

  it 'comes from Node.test' do
    assert_instance_of GraphQL::TestNode, date_test_node
  end

  describe 'when it starts without fields or calls' do
    let(:post_test_node) { Nodes::PostNode.test(@post)}

    before do
      @post = Post.create(id: 123, content: "So many great things", title: "My great post", published_at: Date.new(2010,1,4))
      @comment1 = Comment.create(id: 444, post_id: 123, content: "I agree", rating: 5)
    end

    after do
      @post.destroy
      @comment1.destroy
    end

    it 'returns blank as_result' do
      assert_equal({}, post_test_node.as_result)
    end

    it 'allows access to any defined field' do
      assert_equal(2009, date_test_node["year"])
      assert_equal(123, post_test_node["id"])
      assert_equal({"count" => 1}, post_test_node["comments.first(1) { count }"])
    end

    it 'blows up if you access an undefined field' do
      assert_raises(GraphQL::FieldNotDefinedError) { post_test_node["bogus_field"] }
    end

    describe '#call' do
      it 'allows you to send any defined call as separate arguments' do
        result = date_test_node.call("minus_days", 20)
        assert_equal(2008, result["year"], "it takes calls as separate arguments")
      end

      it 'allows you to send any defined call as a string' do
        result = date_test_node.call("minus_days(400)")
        assert_equal(2007, result["year"], "it takes one call")
      end

      it 'is chainable' do
        result = date_test_node.call("minus_days(200).minus_days(200)")
        assert_equal(2007, result["year"], "it takes multiple calls")
        result_2 = result.call("minus_days(200).minus_days(200)")
        assert_equal(2006, result_2["year"], "it is chainable")
      end

      it 'blows up if you send an undefined call' do
        assert_raises(GraphQL::CallNotDefinedError) { date_test_node.call("bogus_call", 123) }
      end
    end
  end

  describe 'when it starts with fields' do
    let(:date_test_node) { type_class.test(date, fields: ["month"])}
    it 'returns those fields with as_result' do
      assert_equal({"month" => 1}, date_test_node.as_result)
    end

    it 'only allows access to those fields' do
      assert_equal(1, date_test_node["month"])
      assert_raises(RuntimeError) { date_test_node["year"] }
    end

    it 'passes that selection on to children' do
      result = date_test_node.call("minus_days(15)")
      assert_equal({"month" => 12}, result.as_result)
    end
  end

  describe 'when it starts with calls' do
    it 'applies those calls from string' do
      test_node = type_class.test(date, calls: "minus_days(6).minus_days(5)")
      assert_equal(2008, test_node["year"])
    end

    it 'applies those calls from array' do
      test_node = type_class.test(date, calls: ["minus_days", 25])
      assert_equal(2008, test_node["year"])
    end

    it 'applies those calls from array of arrays' do
      test_node = type_class.test(date, calls: [["minus_days", 5], ["minus_days", 6]])
      assert_equal(2008, test_node["year"])
    end
  end
end