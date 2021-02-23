# frozen_string_literal: true
module GraphQL
  module Language
    # Depth-first traversal through the tree, calling hooks at each stop.
    #
    # @example Create a visitor counting certain field names
    #   class NameCounter < GraphQL::Language::Visitor
    #     def initialize(document, field_name)
    #       super(document)
    #       @field_name = field_name
    #       @count = 0
    #     end
    #
    #     attr_reader :count
    #
    #     def on_field(node, parent)
    #       # if this field matches our search, increment the counter
    #       if node.name == @field_name
    #         @count += 1
    #       end
    #       # Continue visiting subfields:
    #       super
    #     end
    #   end
    #
    #   # Initialize a visitor
    #   visitor = NameCounter.new(document, "name")
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

      class DeleteNode; end

      # When this is returned from a visitor method,
      # Then the `node` passed into the method is removed from `parent`'s children.
      DELETE_NODE = DeleteNode.new

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
        result = on_node_with_modifications(@document, nil)
        @result = if result.is_a?(Array)
          result.first
        else
          # The node wasn't modified
          @document
        end
      end

      # Call the user-defined handler for `node`.
      def visit_node(node, parent)
        public_send(node.visit_method, node, parent)
      end

      # The default implementation for visiting an AST node.
      # It doesn't _do_ anything, but it continues to visiting the node's children.
      # To customize this hook, override one of its make_visit_methodes (or the base method?)
      # in your subclasses.
      #
      # For compatibility, it calls hook procs, too.
      # @param node [GraphQL::Language::Nodes::AbstractNode] the node being visited
      # @param parent [GraphQL::Language::Nodes::AbstractNode, nil] the previously-visited node, or `nil` if this is the root node.
      # @return [Array, nil] If there were modifications, it returns an array of new nodes, otherwise, it returns `nil`.
      def on_abstract_node(node, parent)
        if node.equal?(DELETE_NODE)
          # This might be passed to `super(DELETE_NODE, ...)`
          # by a user hook, don't want to keep visiting in that case.
          nil
        else
          # Run hooks if there are any
          new_node = node
          no_hooks = !@visitors.key?(node.class)
          if no_hooks || begin_visit(new_node, parent)
            node.children.each do |child_node|
              new_child_and_node = on_node_with_modifications(child_node, new_node)
              # Reassign `node` in case the child hook makes a modification
              if new_child_and_node.is_a?(Array)
                new_node = new_child_and_node[1]
              end
            end
          end
          end_visit(new_node, parent) unless no_hooks

          if new_node.equal?(node)
            nil
          else
            [new_node, parent]
          end
        end
      end

      # We don't use `alias` here because it breaks `super`
      def self.make_visit_method(node_method)
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{node_method}(node, parent)
            child_mod = on_abstract_node(node, parent)
            # If visiting the children returned changes, continue passing those.
            child_mod || [node, parent]
          end
        RUBY
      end

      make_visit_method :on_argument
      make_visit_method :on_directive
      make_visit_method :on_directive_definition
      make_visit_method :on_directive_location
      make_visit_method :on_document
      make_visit_method :on_enum
      make_visit_method :on_enum_type_definition
      make_visit_method :on_enum_type_extension
      make_visit_method :on_enum_value_definition
      make_visit_method :on_field
      make_visit_method :on_field_definition
      make_visit_method :on_fragment_definition
      make_visit_method :on_fragment_spread
      make_visit_method :on_inline_fragment
      make_visit_method :on_input_object
      make_visit_method :on_input_object_type_definition
      make_visit_method :on_input_object_type_extension
      make_visit_method :on_input_value_definition
      make_visit_method :on_interface_type_definition
      make_visit_method :on_interface_type_extension
      make_visit_method :on_list_type
      make_visit_method :on_non_null_type
      make_visit_method :on_null_value
      make_visit_method :on_object_type_definition
      make_visit_method :on_object_type_extension
      make_visit_method :on_operation_definition
      make_visit_method :on_scalar_type_definition
      make_visit_method :on_scalar_type_extension
      make_visit_method :on_schema_definition
      make_visit_method :on_schema_extension
      make_visit_method :on_type_name
      make_visit_method :on_union_type_definition
      make_visit_method :on_union_type_extension
      make_visit_method :on_variable_definition
      make_visit_method :on_variable_identifier

      private

      # Run the hooks for `node`, and if the hooks return a copy of `node`,
      # copy `parent` so that it contains the copy of that node as a child,
      # then return the copies
      # If a non-array value is returned, consuming functions should ignore
      # said value
      def on_node_with_modifications(node, parent)
        new_node_and_new_parent = visit_node(node, parent)
        if new_node_and_new_parent.is_a?(Array)
          new_node = new_node_and_new_parent[0]
          new_parent = new_node_and_new_parent[1]
          if new_node.is_a?(Nodes::AbstractNode) && !node.equal?(new_node)
            # The user-provided hook returned a new node.
            new_parent = new_parent && new_parent.replace_child(node, new_node)
            return new_node, new_parent
          elsif new_node.equal?(DELETE_NODE)
            # The user-provided hook requested to remove this node
            new_parent = new_parent && new_parent.delete_child(node)
            return nil, new_parent
          elsif new_node_and_new_parent.none? { |n| n == nil || n.class < Nodes::AbstractNode }
            # The user-provided hook returned an array of who-knows-what
            # return nil here to signify that no changes should be made
            nil
          else
            new_node_and_new_parent
          end
        else
          # The user-provided hook didn't make any modifications.
          # In fact, the hook might have returned who-knows-what, so
          # ignore the return value and use the original values.
          new_node_and_new_parent
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
        hooks.each do |proc|
          return false if proc.call(node, parent) == SKIP
        end
        true
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
