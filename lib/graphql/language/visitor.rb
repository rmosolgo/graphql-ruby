# frozen_string_literal: true
module GraphQL
  module Language
    # Depth-first traversal through the tree, calling hooks at each stop.
    #
    # @example Create a visitor counting certain field names
    #   class NameCounter < GraphQL::Language::Visitor
    #     def initialize(document, field_name)
    #       super(document)
    #       @field_name
    #       @count = 0
    #     end
    #
    #     attr_reader :count
    #
    #     def on_field(node, parent)
    #       # if this field matches our search, increment the counter
    #       if node.name == @field_name
    #         @count = 0
    #       end
    #       # Continue visiting subfields:
    #       super
    #     end
    #   end
    #
    #   # Initialize a visitor
    #   visitor = GraphQL::Language::Visitor.new(document, "name")
    #   # Run it
    #   visitor.visit
    #   # Check the result
    #   visitor.count
    #   # => 3
    class Visitor
      # If any hook returns this value, the {Visitor} stops visiting this
      # node right away
      # @deprecated Use `super` to continue the visit; or don't call it to halt.
      SKIP = :_skip

      def initialize(document)
        @document = document
        @visitors = {}
        @result = nil
      end

      # @return [GraphQL::Language::Nodes::Document] The document with any modifications applied
      attr_reader :result

      # Get a {NodeVisitor} for `node_class`
      # @param node_class [Class] The node class that you want to listen to
      # @return [NodeVisitor]
      #
      # @example Run a hook whenever you enter a new Field
      #   visitor[GraphQL::Language::Nodes::Field] << ->(node, parent) { p "Here's a field" }
      # @deprecated see `on_` methods, like {#on_field}
      def [](node_class)
        @visitors[node_class] ||= NodeVisitor.new
      end

      # Visit `document` and all children, applying hooks as you go
      # @return [void]
      def visit
        @result, _nil_parent = on_node_with_modifications(@document, nil)
      end

      # The default implementation for visiting an AST node.
      # It doesn't _do_ anything, but it continues to visiting the node's children.
      # To customize this hook, override one of its aliases (or the base method?)
      # in your subclasses.
      #
      # For compatibility, it calls hook procs, too.
      # @param node [GraphQL::Language::Nodes::AbstractNode] the node being visited
      # @param parent [GraphQL::Language::Nodes::AbstractNode, nil] the previously-visited node, or `nil` if this is the root node.
      # @return [void]
      def on_abstract_node(node, parent)
        # Run hooks if there are any
        begin_hooks_ok = @visitors.none? || begin_visit(node, parent)
        if begin_hooks_ok
          node.children.each do |child_node|
            # Reassign `node` in case the child hook makes a modification
            _new_child_node, node = on_node_with_modifications(child_node, node)
          end
        end
        @visitors.any? && end_visit(node, parent)
        return node, parent
      end

      alias :on_argument :on_abstract_node
      alias :on_directive :on_abstract_node
      alias :on_directive_definition :on_abstract_node
      alias :on_directive_location :on_abstract_node
      alias :on_document :on_abstract_node
      alias :on_enum :on_abstract_node
      alias :on_enum_type_definition :on_abstract_node
      alias :on_enum_type_extension :on_abstract_node
      alias :on_enum_value_definition :on_abstract_node
      alias :on_field :on_abstract_node
      alias :on_field_definition :on_abstract_node
      alias :on_fragment_definition :on_abstract_node
      alias :on_fragment_spread :on_abstract_node
      alias :on_inline_fragment :on_abstract_node
      alias :on_input_object :on_abstract_node
      alias :on_input_object_type_definition :on_abstract_node
      alias :on_input_object_type_extension :on_abstract_node
      alias :on_input_value_definition :on_abstract_node
      alias :on_interface_type_definition :on_abstract_node
      alias :on_interface_type_extension :on_abstract_node
      alias :on_list_type :on_abstract_node
      alias :on_non_null_type :on_abstract_node
      alias :on_null_value :on_abstract_node
      alias :on_object_type_definition :on_abstract_node
      alias :on_object_type_extension :on_abstract_node
      alias :on_operation_definition :on_abstract_node
      alias :on_scalar_type_definition :on_abstract_node
      alias :on_scalar_type_extension :on_abstract_node
      alias :on_schema_definition :on_abstract_node
      alias :on_schema_extension :on_abstract_node
      alias :on_type_name :on_abstract_node
      alias :on_union_type_definition :on_abstract_node
      alias :on_union_type_extension :on_abstract_node
      alias :on_variable_definition :on_abstract_node
      alias :on_variable_identifier :on_abstract_node

      private

      # Run the hooks for `node`, and if the hooks return a copy of `node`,
      # copy `parent` so that it contains the copy of that node as a child,
      # then return the copies
      def on_node_with_modifications(node, parent)
        new_node, new_parent = public_send(node.visit_method, node, parent)
        if new_node.is_a?(Nodes::AbstractNode) && !node.equal?(new_node)
          # The user-provided hook returned a new node.
          new_parent = new_parent && new_parent.replace_child(node, new_node)
          return new_node, new_parent
        else
          # The user-provided hook didn't make any modifications.
          # In fact, the hook might have returned who-knows-what, so
          # ignore the return value and use the original values.
          return node, parent
        end
      end

      def begin_visit(node, parent)
        node_visitor = self[node.class]
        self.class.apply_hooks(node_visitor.enter, node, parent)
      end

      # Should global `leave` visitors come first or last?
      def end_visit(node, parent)
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
  end
end
