# Depth-first traversal through the tree, calling hooks at each stop.
#
# @example Create a visitor, add hooks, then search a document
#   total_field_count = 0
#   visitor = GraphQL::Language::Visitor.new
#   # Whenever you find a field, increment the field count:
#   visitor[GraphQL::Language::Nodes::Field] << -> (node) { total_field_count += 1 }
#   # When we finish, print the field count:
#   visitor[GraphQL::Language::Nodes::Document].leave << -> (node) { p total_field_count }
#   visitor.visit(document)
#   # => 6
#
class GraphQL::Language::Visitor
  # If any hook returns this value, the {Visitor} stops visiting this
  # node right away
  SKIP = :_skip

  # @return [Array<Proc>] Hooks to call when entering _any_ node
  attr_reader :enter
  # @return [Array<Proc>] Hooks to call when leaving _any_ node
  attr_reader :leave

  def initialize
    @visitors = {}
    @enter = []
    @leave = []
  end

  # Get a {NodeVisitor} for `node_class`
  # @param node_class [Class] The node class that you want to listen to
  # @return [NodeVisitor]
  #
  # @example Run a hook whenever you enter a new Field
  #   visitor[GraphQL::Language::Nodes::Field] << -> (node, parent) { p "Here's a field" }
  def [](node_class)
    @visitors[node_class] ||= NodeVisitor.new
  end

  # Visit `root` and all children, applying hooks as you go
  # @param root [GraphQL::Language::Nodes::AbstractNode] some node to start parsing on
  # @return [void]
  def visit(root, parent=nil)
    begin_visit(root, parent) &&
      root.children.reduce(true) { |memo, child| memo && visit(child, root) }
    end_visit(root, parent)
  end

  private

  def begin_visit(node, parent)
    self.class.apply_hooks(enter, node, parent)
    node_visitor = self[node.class]
    self.class.apply_hooks(node_visitor.enter, node, parent)
  end

  # Should global `leave` visitors come first or last?
  def end_visit(node, parent)
    self.class.apply_hooks(leave, node, parent)
    node_visitor = self[node.class]
    self.class.apply_hooks(node_visitor.leave, node, parent)
  end

  # If one of the visitors returns SKIP, stop visiting this node
  def self.apply_hooks(hooks, node, parent)
    hooks.reduce(true) { |memo, proc| memo && (proc.call(node, parent) != SKIP) }
  end

  # Collect `enter` and `leave` hooks for classes in {GraphQL::Language::Nodes}
  #
  # Access {NodeVisitor}s via {GraphQL::Language::Visitor#[]}
  class NodeVisitor
    # @return [Array<Proc>] Hooks to call when entering a node of this type
    attr_reader :enter
    # @return [Array<Proc>] Hooks to call when leaving a node of this type
    attr_reader :leave

    def initialize
      @enter = []
      @leave = []
    end

    # Shorthand to add a hook to the {#enter} array
    # @param hook [Proc] A hook to add
    def <<(hook)
      enter << hook
    end
  end
end
