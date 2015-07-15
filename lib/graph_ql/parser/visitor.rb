# Depth-first traversal through the tree, calling hooks at each stop.
#
# @example: Create a visitor, add hooks, then search a document
#   total_field_count = 0
#   visitor = GraphQL::Visitor.new
#   visitor[GraphQL::Nodes::Field] << -> (node) { total_field_count += 1 }
#   visitor[GraphQL::Nodes::Document].leave << -> (node) { p total_field_count }
#   visitor.visit(document)
#   # => 6
#
class GraphQL::Visitor
  SKIP = :_skip

  attr_reader :enter, :leave
  def initialize
    @visitors = {}
    @enter = []
    @leave = []
  end

  def [](node_class)
    @visitors[node_class] ||= NodeVisitor.new
  end

  # Apply built-up vistors to `document`
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

  class NodeVisitor
    attr_reader :enter, :leave
    def initialize
      @enter = []
      @leave = []
    end

    def <<(hook)
      enter << hook
    end
  end
end
