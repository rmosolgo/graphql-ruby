module GraphQL
  module Language
    # Depth-first traversal through the tree, calling hooks at each stop.
    #
    # @example Create a visitor, add hooks, then search a document
    #   total_field_count = 0
    #   visitor = GraphQL::Language::Visitor.new(document)
    #   # Whenever you find a field, increment the field count:
    #   visitor[GraphQL::Language::Nodes::Field] << -> (node) { total_field_count += 1 }
    #   # When we finish, print the field count:
    #   visitor[GraphQL::Language::Nodes::Document].leave << -> (node) { p total_field_count }
    #   visitor.visit
    #   # => 6
    #
    class Visitor
      # If any hook returns this value, the {Visitor} stops visiting this
      # node right away
      SKIP = :_skip

      # @return [Array<Proc>] Hooks to call when entering _any_ node
      attr_reader :enter
      # @return [Array<Proc>] Hooks to call when leaving _any_ node
      attr_reader :leave

      def initialize(document, follow_fragments: false)
        @document = document
        @follow_fragments = follow_fragments
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

      # Visit `document` and all children, applying hooks as you go
      # @return [void]
      def visit
        visit_node(@document, nil)
      end

      private

      def visit_node(node, parent)
        begin_hooks_result = begin_visit(node, parent)
        if begin_hooks_result
          child_result = node.children.reduce(true) { |memo, child| memo && visit_node(child, node) }
          if child_result && @follow_fragments && node.is_a?(GraphQL::Language::Nodes::FragmentSpread)
            frag_defn = fragments[node.name]
            frag_defn && visit_node(frag_defn, node)
          end
        end
        end_visit(node, parent)
      end

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

      # @return [Hash<String, GraphQL::Language::Nodes::FragmentDefinition>]
      def fragments
        @fragments ||= @document.definitions.each_with_object({}) do |defn, memo|
          if defn.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
            memo[defn.name] = defn
          end
        end
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
  end
end
