require 'spec_helper'

describe GraphQL::Parser::Transform do
  let(:transform) { GraphQL::TRANSFORM }
  let(:parser) { GraphQL::PARSER }

  describe '#apply' do
    describe 'query' do
      it 'parses node and variables' do
        tree = parser.query.parse(%{
          like_page(<page_info>) { page { $fragment, likes } }

          <page_info>: {
            "page" : { "id": 4},
            "person" : {"id": 4}
          }
          <other>: {
            "page" : { "id": 4},
            "person" : {"id": 4}
          }

          $fragment: {
            id, name
          }
          })
        res = transform.apply(tree)
        assert_equal 1, res.nodes.length
        assert_equal "like_page", res.nodes[0].identifier
        assert_equal ["<page_info>"], res.nodes[0].arguments
        assert_equal ["<page_info>", "<other>"], res.variables.map(&:identifier)
        assert_equal ["$fragment"], res.fragments.map(&:identifier)
      end
    end

    describe 'nodes' do
      it 'turns a simple node into a Node' do
        tree = parser.node.parse("post(123) { name }")
        res = transform.apply(tree)
        assert(res.is_a?(GraphQL::Syntax::Node), 'it gets a node')
      end

      it 'turns a node into a Node' do
        tree = parser.node.parse("person(1) { name, check_ins.last(4) { count, edges { node { id } }  } }")
        res = transform.apply(tree)
        assert(res.is_a?(GraphQL::Syntax::Node), 'it gets a node')
        assert(res.identifier == "person")
        assert(res.fields.length == 2)
        assert(res.fields[0].is_a?(GraphQL::Syntax::Field), 'it gets a field')
        assert(res.fields[1].is_a?(GraphQL::Syntax::Field), 'it gets an field with fields')
        assert(res.fields[1].calls.first.is_a?(GraphQL::Syntax::Call), 'it gets a call')
      end
    end

    describe 'fields' do
      it 'turns a field into a Field' do
        tree = parser.field.parse("friends")
        res = transform.apply(tree)
        assert(res.is_a?(GraphQL::Syntax::Field))
        assert(res.identifier == "friends")
      end

      it 'gets aliases' do
        tree = parser.field.parse("friends as pals")
        res = transform.apply(tree)
        assert(res.is_a?(GraphQL::Syntax::Field))
        assert(res.identifier == "friends")
        assert(res.alias_name == "pals")
      end

      it 'gets calls' do
        tree = parser.field.parse("friends.orderby(name, birthdate).first(3)")
        res = transform.apply(tree)
        assert_equal "orderby", res.calls[0].identifier
        assert_equal ["name", "birthdate"], res.calls[0].arguments
        assert_equal "first", res.calls[1].identifier
        assert_equal ["3"], res.calls[1].arguments
      end

      describe 'fields that return objects' do
        it 'gets them' do
          tree = parser.field.parse("friends { count }")
          res = transform.apply(tree)
          assert_equal "friends", res.identifier
          assert_equal 1, res.fields.length
        end
        it 'gets them with aliases' do
          tree = parser.field.parse("friends as pals { count }")
          res = transform.apply(tree)
          assert_equal "friends", res.identifier
          assert_equal "pals", res.alias_name
          assert_equal 1, res.fields.length
        end
        it 'gets them with calls' do
          tree = parser.field.parse("friends.orderby(name, birthdate).last(1) { count }")
          res = transform.apply(tree)
          assert_equal "friends", res.identifier
          assert_equal 1, res.fields.length
          assert_equal 2, res.calls.length
        end
        it 'gets them with calls and aliases' do
          tree = parser.field.parse("friends.orderby(name, birthdate).last(1) as pals { count }")
          res = transform.apply(tree)
          assert_equal "friends", res.identifier
          assert_equal "pals", res.alias_name
          assert_equal 1, res.fields.length
          assert_equal 2, res.calls.length
        end
      end
    end

    describe 'calls' do
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

      it 'gets calls with variable identifiers' do
        tree = parser.call.parse("like_page(<page_info>)")
        res = transform.apply(tree)
        assert_equal "<page_info>", res.arguments[0]
      end
    end

    describe 'variables' do
      it 'gets variables' do
        tree = parser.variable.parse(%{
          <page_info>: {
            "page" : { "id": 4},
            "person" : {"id": 4}
          }
          })
        res = transform.apply(tree)
        assert_equal "<page_info>", res.identifier
      end
    end

    describe 'fragments' do
      focus
      it 'gets fragments' do
        tree = parser.fragment.parse(%{$frag: { id, name, $otherFrag }})
        res = transform.apply(tree)
        assert_equal "$frag", res.identifier
        assert_equal ["id", "name", "$otherFrag"], res.fields.map(&:identifier)
      end
    end
  end
end