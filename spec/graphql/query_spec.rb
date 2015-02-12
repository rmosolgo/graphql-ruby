require 'spec_helper'

describe GraphQL::Query do
  let(:query_string) { "post(123) { title, content } "}
  let(:context) { {person_name: "Han Solo" }}
  let(:query) { GraphQL::Query.new(query_string, namespace: Nodes, context: context) }
  let(:result) { query.as_json }

  before do
    @post = Post.create(id: 123, content: "So many great things", title: "My great post")
    @comment1 = Comment.create(id: 444, post_id: 123, content: "I agree", rating: 5)
    @comment2 = Comment.create(id: 445, post_id: 123, content: "I disagree", rating: 1)
    @like1 = Like.create(id: 991, post_id: 123)
    @like2 = Like.create(id: 992, post_id: 123)
  end

  after do
    @post.destroy
    @comment1.destroy
    @comment2.destroy
    @like1.destroy
    @like2.destroy
  end

  describe '#root' do
    it 'contains the first node of the graph' do
      assert query.root.is_a?(GraphQL::Syntax::Node)
    end
  end

  describe '#as_json' do
    it 'performs the root node call' do
      assert_send([Nodes::PostNode, :call, "123"])
      query.as_json
    end

    it 'finds fields that delegate to a target' do
      assert_equal result, {"123" => {"title" => "My great post", "content" => "So many great things"}}
    end

    describe 'with multiple roots' do
      let(:query_string) { "comment(444, 445) { content } "}
      it 'adds each as a key-value of the response' do
        assert_equal ["444", "445"], result.keys
      end
    end

    describe 'when aliasing things' do
      let(:query_string) { "post(123) { title as headline, content as what_it_says }"}

      it 'applies aliases to fields' do
        assert_equal @post.title, result["123"]["headline"]
        assert_equal @post.content, result["123"]["what_it_says"]
      end

      it 'applies aliases to edges' # dunno the syntax yet
    end

    describe 'when requesting fields defined on the node' do
      let(:query_string) { "post(123) { length } "}
      it 'finds fields defined on the node' do
        assert_equal 20, result["123"]["length"]
      end
    end

    describe 'when accessing custom fields' do
      let(:query_string) { "comment(444) { letters }"}
      it 'uses the custom field' do
        assert_equal "I agree", result["444"]["letters"]
      end

      describe 'when making calls on fields' do
        let(:query_string) { "comment(444) {
            letters.select(4, 3),
            letters.from(3).for(2) as snippet
          }"}

        it 'works with aliases' do
          assert result["444"]["snippet"].present?
        end

        it 'applies calls' do
          assert_equal "gr", result["444"]["snippet"]
        end

        it 'applies calls with multiple arguments' do
          assert_equal "ree", result["444"]["letters"]
        end
      end

      describe 'when requesting fields overriden on a child class' do
        let(:query_string) { 'stupid_thumb_up(991) { id }'}
        it 'uses the child implementation' do
          assert_equal '991991', result["991991"]["id"]
        end
      end
    end

    describe 'when requesting an undefined field' do
      let(:query_string) { "post(123) { destroy } "}
      it 'raises a FieldNotDefined error' do
        assert_raises(GraphQL::FieldNotDefinedError) { query.as_json }
        assert(Post.find(123).present?)
      end
    end

    describe 'when the root call doesnt have an argument' do
      let(:query_string) { "viewer() { name }"}
      it 'calls the node with no arguments' do
        assert_send([Nodes::ViewerNode, :call])
        query.as_json
      end
    end

    describe  'when requesting a collection' do
      let(:query_string) { "post(123) {
          title,
          comments { count, edges { cursor, node { content } } }
        }"}

      it 'returns collection data' do
        assert_equal result, {
            "123" => {
              "title" => "My great post",
              "comments" => {
                "count" => 2,
                "edges" => [
                  { "cursor" => "444", "node" => {"content" => "I agree"} },
                  { "cursor" => "445", "node" => {"content" => "I disagree"}}
                ]
            }}}
      end
    end

    describe  'when making calls on a collection' do
      let(:query_string) { "post(123) { comments.first(1) { edges { cursor, node { content } } } }"}

      it 'executes those calls' do
        assert_equal result, {
            "123" => {
              "comments" => {
                "edges" => [
                  { "cursor" => "444", "node" => { "content" => "I agree"} }
                ]
            }}}
      end
    end

    describe  'when making DEEP calls on a collection' do
      let(:query_string) { "post(123) { comments.after(444).first(1) {
            edges { cursor, node { content } }
          }}"}

      it 'executes those calls' do
        assert_equal result, {
            "123" => {
              "comments" => {
                "edges" => [
                  {
                    "cursor" => "445",
                    "node" => { "content" => "I disagree"}
                  }
                ]
            }}}
      end
    end

    describe  'when requesting fields at collection-level' do
      let(:query_string) { "post(123) { comments { average_rating } }"}

      it 'executes those calls' do
        assert_equal result, { "123" => { "comments" => { "average_rating" => 3 } } }
      end
    end

    describe  'when making calls on node fields' do
      let(:query_string) { "post(123) { comments { edges { node { letters.from(3).for(3) }} } }"}
      it 'makes calls on the fields' do
        assert_equal ["gre", "isa"], result["123"]["comments"]["edges"].map {|e| e["node"]["letters"] }
      end
    end

    describe  'when requesting collection-level fields that dont exist' do
      let(:query_string) { "post(123) { comments { bogus_field } }"}

      it 'raises FieldNotDefined' do
        assert_raises(GraphQL::FieldNotDefinedError) { query.as_json }
      end
    end
  end

  describe '.default_namespace=' do
    let(:query) { GraphQL::Query.new(query_string) }
    after { GraphQL::Query.default_namespace = nil }

    it 'uses that namespace for lookups' do
      GraphQL::Query.default_namespace = Nodes
      assert_equal result, {
        "123" => {
          "title" => "My great post",
          "content" => "So many great things"
        }
      }
    end
  end

  describe 'when edge classes were named explicitly' do
    let(:query_string) { "post(123) { likes { any, edges { node { id } } } }"}

    it 'gets node values' do
      assert_equal [991,992], result["123"]["likes"]["edges"].map {|e|  e["node"]["id"] }
    end

    it 'gets edge values' do
      assert_equal true, result["123"]["likes"]["any"]
    end
  end

  describe '#context' do
    let(:query_string) { "context() { person_name }"}

    it 'is accessible inside nodes' do
      assert_equal result, {"context" => {"person_name" => "Han Solo"}}
    end

    describe 'inside edges' do
      let(:query_string) { "post(123) { comments { viewer_name_length } }"}
      it 'is accessible' do
        assert_equal 8, result["123"]["comments"]["viewer_name_length"]
      end
    end
  end

  describe 'parsing error' do
    let(:query_string) { "\n\n<< bogus >>"}

    it 'raises SyntaxError' do
      assert_raises(GraphQL::SyntaxError) { result }
    end

    it 'contains line an character number' do
      err = assert_raises(GraphQL::SyntaxError) { result }
      assert_match(/1, 1/, err.to_s)
    end

    it 'contains sample of text' do
      err = assert_raises(GraphQL::SyntaxError) { result }
      assert_includes(err.to_s, "<< bogus >>")
    end
  end
end