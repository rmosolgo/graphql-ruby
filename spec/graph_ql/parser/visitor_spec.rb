require 'spec_helper'

describe GraphQL::Visitor do
  let(:document) { GraphQL.parse("
    query cheese { cheese(id: 1) { flavor, source, producers(first: 3) { name } } }
    fragment cheeseFields on Cheese { flavor }
    ")}
  let(:counts) { {fields_entered: 0, arguments_entered: 0, arguments_left: 0, argument_names: []} }

  let(:visitor) do
    v = GraphQL::Visitor.new
    v[GraphQL::Nodes::Field] << -> (node) { counts[:fields_entered] += 1 }
    # two ways to set up enter hooks:
    v[GraphQL::Nodes::Argument] <<       -> (node) { counts[:argument_names] << node.name }
    v[GraphQL::Nodes::Argument].enter << -> (node) { counts[:arguments_entered] += 1}
    v[GraphQL::Nodes::Argument].leave << -> (node) { counts[:arguments_left] += 1 }

    v[GraphQL::Nodes::Document].leave << -> (node) { counts[:finished] = true }
    v
  end

  it 'calls hooks during a depth-first tree traversal' do
    assert_equal(2, visitor[GraphQL::Nodes::Argument].enter.length)
    visitor.visit(document)
    assert_equal(6, counts[:fields_entered])
    assert_equal(2, counts[:arguments_entered])
    assert_equal(2, counts[:arguments_left])
    assert_equal(["id", "first"], counts[:argument_names])
    assert(counts[:finished])
  end
end
