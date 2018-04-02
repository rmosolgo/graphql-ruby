# frozen_string_literal: true
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
  let(:hooks_counts) { {fields_entered: 0, arguments_entered: 0, arguments_left: 0, argument_names: []} }

  let(:hooks_visitor) do
    v = GraphQL::Language::Visitor.new(document)
    counts = hooks_counts
    v[GraphQL::Language::Nodes::Field] << ->(node, parent) { counts[:fields_entered] += 1 }
    # two ways to set up enter hooks:
    v[GraphQL::Language::Nodes::Argument] <<       ->(node, parent) { counts[:argument_names] << node.name }
    v[GraphQL::Language::Nodes::Argument].enter << ->(node, parent) { counts[:arguments_entered] += 1}
    v[GraphQL::Language::Nodes::Argument].leave << ->(node, parent) { counts[:arguments_left] += 1 }

    v[GraphQL::Language::Nodes::Document].leave << ->(node, parent) { counts[:finished] = true }
    v
  end

  class VisitorSpecVisitor < GraphQL::Language::Visitor
    attr_reader :counts
    def initialize(document)
      @counts = {fields_entered: 0, arguments_entered: 0, arguments_left: 0, argument_names: []}
      super
    end

    def on_field(node, parent)
      counts[:fields_entered] += 1
      super(node, parent)
    end

    def on_argument(node, parent)
      counts[:argument_names] << node.name
      counts[:arguments_entered] += 1
      super
    ensure
      counts[:arguments_left] += 1
    end

    def on_document(node, parent)
      counts[:finished] = true
      super
    end
  end

  class SkippingVisitor < VisitorSpecVisitor
    def on_document(_n, _p)
      SKIP
    end
  end

  let(:class_based_visitor) { VisitorSpecVisitor.new(document) }
  let(:class_based_counts) { class_based_visitor.counts }

  it "has an array of hooks" do
    assert_equal(2, hooks_visitor[GraphQL::Language::Nodes::Argument].enter.length)
  end

  [:hooks, :class_based].each do |visitor_type|
    it "#{visitor_type} visitor calls hooks during a depth-first tree traversal" do
      visitor = public_send("#{visitor_type}_visitor")
      visitor.visit
      counts = public_send("#{visitor_type}_counts")
      assert_equal(6, counts[:fields_entered])
      assert_equal(2, counts[:arguments_entered])
      assert_equal(2, counts[:arguments_left])
      assert_equal(["id", "first"], counts[:argument_names])
      assert(counts[:finished])
    end

    describe "Visitor::SKIP" do
      let(:class_based_visitor) { SkippingVisitor.new(document) }

      it "#{visitor_type} visitor skips the rest of the node" do
        visitor = public_send("#{visitor_type}_visitor")
        if visitor_type == :hooks
          visitor[GraphQL::Language::Nodes::Document] << ->(node, parent) { GraphQL::Language::Visitor::SKIP }
        end
        visitor.visit
        counts = public_send("#{visitor_type}_counts")
        assert_equal(0, counts[:fields_entered])
      end
    end
  end
end
