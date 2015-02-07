require 'spec_helper'

describe GraphQL::Transform do
  let(:transform) { GraphQL::TRANSFORM }
  let(:parser) { GraphQL::PARSER }

  describe '#apply' do

    it 'turns a simple node into a Node' do
      tree = parser.parse("post(123) { name }")
      res = transform.apply(tree)
      assert(res.is_a?(GraphQL::Syntax::Node), 'it gets a node')
    end

    it 'turns a node into a Node' do
      tree = parser.parse("viewer() { name, friends.first(10) { birthdate } }")
      res = transform.apply(tree)
      assert(res.is_a?(GraphQL::Syntax::Node), 'it gets a node')
      assert(res.identifier == "viewer")
      assert(res.fields.length == 2)
      assert(res.fields[0].is_a?(GraphQL::Syntax::Field), 'it gets a field')
      assert(res.fields[1].is_a?(GraphQL::Syntax::Edge), 'it gets an edge')
    end

    it 'turns a field into a Field' do
      tree = parser.field.parse("friends")
      res = transform.apply(tree)
      assert(res.is_a?(GraphQL::Syntax::Field))
      assert(res.identifier == "friends")
    end

    it 'turns edge into an Edge' do
      tree = parser.edge.parse("friends.orderby(name, birthdate).first(2) { count, edges { node { name } } }")
      res = transform.apply(tree)
      assert(res.is_a?(GraphQL::Syntax::Edge), 'it gets the Edge')
      assert(res.identifier == "friends")
      assert(res.calls.length == 2, 'it tracks calls')
      assert(res.calls[0].identifier == "orderby")
      assert(res.calls[1].identifier == "first")
      assert_equal(res.call_hash, {"orderby" => ["name", "birthdate"], "first" => ["2"]})
    end

    it 'turns call into a Call' do
      tree = parser.call.parse("node(4, 6, tree)")
      res = transform.apply(tree)
      assert(res.is_a?(GraphQL::Syntax::Call))
      assert(res.identifier == "node")
      assert(res.arguments == ["4", "6", "tree"])
    end

    it 'turns a call without an argument into a Call' do
      tree = parser.call.parse("viewer()")
      res = transform.apply(tree)
      assert(res.is_a?(GraphQL::Syntax::Call))
      assert(res.identifier == "viewer")
      assert(res.arguments.length == 0)
    end
  end
end