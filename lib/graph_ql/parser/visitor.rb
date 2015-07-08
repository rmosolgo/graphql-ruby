# Depth-first traversal through the tree, calling hooks at each stop
#
#
class GraphQL::Visitor
  def initialize
    @visitors = {}
  end

  def [](node_class)
    @visitors[node_class] ||= NodeVisitor.new
  end

  # Apply built-up vistors to `document`
  def visit(root)
    node_visitor = self[root.class]
    node_visitor.begin_visit(root)
    root.children.map { |child| visit(child) }
    node_visitor.end_visit(root)
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

    def begin_visit(node)
      enter.map{ |proc| proc.call(node) }
    end

    def end_visit(node)
      leave.map{ |proc| proc.call(node) }
    end
  end
end
