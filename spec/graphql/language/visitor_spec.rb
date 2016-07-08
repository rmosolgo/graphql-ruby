require "spec_helper"

describe GraphQL::Language::Visitor do
  let(:document) { GraphQL.parse("
    query cheese {
      cheese(id: 1) {
        flavor,
        source,
        producers(first: 3) {
          name
        }
        ... cheeseFields
      }
    }

    fragment cheeseFields on Cheese { flavor }
    ")}
  let(:counts) { {fields_entered: 0, arguments_entered: 0, arguments_left: 0, argument_names: []} }
  let(:follow_fragments) { false }

  let(:visitor) do
    v = GraphQL::Language::Visitor.new(document, follow_fragments: follow_fragments)
    v[GraphQL::Language::Nodes::Field] << -> (node, parent) { counts[:fields_entered] += 1 }
    # two ways to set up enter hooks:
    v[GraphQL::Language::Nodes::Argument] <<       -> (node, parent) { counts[:argument_names] << node.name }
    v[GraphQL::Language::Nodes::Argument].enter << -> (node, parent) { counts[:arguments_entered] += 1}
    v[GraphQL::Language::Nodes::Argument].leave << -> (node, parent) { counts[:arguments_left] += 1 }

    v[GraphQL::Language::Nodes::Document].leave << -> (node, parent) { counts[:finished] = true }
    v
  end

  it "calls hooks during a depth-first tree traversal" do
    assert_equal(2, visitor[GraphQL::Language::Nodes::Argument].enter.length)
    visitor.visit
    assert_equal(6, counts[:fields_entered])
    assert_equal(2, counts[:arguments_entered])
    assert_equal(2, counts[:arguments_left])
    assert_equal(["id", "first"], counts[:argument_names])
    assert(counts[:finished])
  end

  describe "following fragments" do
    let(:follow_fragments) { true }
    it "follows fragments from their spreads" do
      visitor.visit
      # This is one greater than the previous example
      # because it visited the cheeseFields fragment twice
      assert_equal(7, counts[:fields_entered])
    end
  end

  describe "Visitor::SKIP" do
    it "skips the rest of the node" do
      visitor[GraphQL::Language::Nodes::Document] << -> (node, parent) { GraphQL::Language::Visitor::SKIP }
      visitor.visit
      assert_equal(0, counts[:fields_entered])
    end
  end
end
