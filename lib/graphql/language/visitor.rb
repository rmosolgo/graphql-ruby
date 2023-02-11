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
        # `@document` may be any kind of node:
        visit_method = :"#{@document.visit_method}_with_modifications"
        result = public_send(visit_method, @document, nil)
        @result = if result.is_a?(Array)
          result.first
        else
          # The node wasn't modified
          @document
        end
      end

      # We don't use `alias` here because it breaks `super`
      def self.make_visit_methods(ast_node_class)
        node_method = ast_node_class.visit_method
        children_of_type = ast_node_class.children_of_type
        child_visit_method = :"#{node_method}_children"

        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          # The default implementation for visiting an AST node.
          # It doesn't _do_ anything, but it continues to visiting the node's children.
          # To customize this hook, override one of its make_visit_methods (or the base method?)
          # in your subclasses.
          #
          # For compatibility, it calls hook procs, too.
          # @param node [GraphQL::Language::Nodes::AbstractNode] the node being visited
          # @param parent [GraphQL::Language::Nodes::AbstractNode, nil] the previously-visited node, or `nil` if this is the root node.
          # @return [Array, nil] If there were modifications, it returns an array of new nodes, otherwise, it returns `nil`.
          def #{node_method}(node, parent)
            if node.equal?(DELETE_NODE)
              # This might be passed to `super(DELETE_NODE, ...)`
              # by a user hook, don't want to keep visiting in that case.
              [node, parent]
            else
              # Run hooks if there are any
              new_node = node
              no_hooks = !@visitors.key?(node.class)
              if no_hooks || begin_visit(new_node, parent)
                #{
                  if method_defined?(child_visit_method)
                    "new_node = #{child_visit_method}(new_node)"
                  elsif children_of_type
                    children_of_type.map do |child_accessor, child_class|
                      "node.#{child_accessor}.each do |child_node|
                        new_child_and_node = #{child_class.visit_method}_with_modifications(child_node, new_node)
                        # Reassign `node` in case the child hook makes a modification
                        if new_child_and_node.is_a?(Array)
                          new_node = new_child_and_node[1]
                        end
                      end"
                    end.join("\n")
                  else
                    ""
                  end
                }
              end
              end_visit(new_node, parent) unless no_hooks

              if new_node.equal?(node)
                [node, parent]
              else
                [new_node, parent]
              end
            end
          end

          def #{node_method}_with_modifications(node, parent)
            new_node_and_new_parent = #{node_method}(node, parent)
            apply_modifications(node, parent, new_node_and_new_parent)
          end
        RUBY
      end

      def on_document_children(document_node)
        new_node = document_node
        document_node.children.each do |child_node|
          visit_method = :"#{child_node.visit_method}_with_modifications"
          new_child_and_node = public_send(visit_method, child_node, new_node)
          # Reassign `node` in case the child hook makes a modification
          if new_child_and_node.is_a?(Array)
            new_node = new_child_and_node[1]
          end
        end
        new_node
      end

      def on_field_children(new_node)
        new_node.arguments.each do |arg_node| # rubocop:disable Development/ContextIsPassedCop
          new_child_and_node = on_argument_with_modifications(arg_node, new_node)
          # Reassign `node` in case the child hook makes a modification
          if new_child_and_node.is_a?(Array)
            new_node = new_child_and_node[1]
          end
        end
        new_node = visit_directives(new_node)
        new_node = visit_selections(new_node)
        new_node
      end

      def visit_directives(new_node)
        new_node.directives.each do |dir_node|
          new_child_and_node = on_directive_with_modifications(dir_node, new_node)
          # Reassign `node` in case the child hook makes a modification
          if new_child_and_node.is_a?(Array)
            new_node = new_child_and_node[1]
          end
        end
        new_node
      end

      def visit_selections(new_node)
        new_node.selections.each do |selection|
          new_child_and_node = case selection
          when GraphQL::Language::Nodes::Field
            on_field_with_modifications(selection, new_node)
          when GraphQL::Language::Nodes::InlineFragment
            on_inline_fragment_with_modifications(selection, new_node)
          when GraphQL::Language::Nodes::FragmentSpread
            on_fragment_spread_with_modifications(selection, new_node)
          else
            raise ArgumentError, "Invariant: unexpected field selection #{selection.class} (#{selection.inspect})"
          end
          # Reassign `node` in case the child hook makes a modification
          if new_child_and_node.is_a?(Array)
            new_node = new_child_and_node[1]
          end
        end
        new_node
      end

      def on_fragment_definition_children(new_node)
        new_node = visit_directives(new_node)
        new_node = visit_selections(new_node)
        new_node
      end

      alias :on_inline_fragment_children :on_fragment_definition_children

      def on_operation_definition_children(new_node)
        new_node.variables.each do |arg_node|
          new_child_and_node = on_variable_definition_with_modifications(arg_node, new_node)
          # Reassign `node` in case the child hook makes a modification
          if new_child_and_node.is_a?(Array)
            new_node = new_child_and_node[1]
          end
        end
        new_node = visit_directives(new_node)
        new_node = visit_selections(new_node)
        new_node
      end

      def on_argument_children(new_node)
        new_node.children.each do |value_node|
          new_child_and_node = case value_node
          when Language::Nodes::VariableIdentifier
            on_variable_identifier_with_modifications(value_node, new_node)
          when Language::Nodes::InputObject
            on_input_object_with_modifications(value_node, new_node)
          when Language::Nodes::Enum
            on_enum_with_modifications(value_node, new_node)
          when Language::Nodes::NullValue
            on_null_value_with_modifications(value_node, new_node)
          else
            raise ArgumentError, "Invariant: unexpected argument value node #{value_node.class} (#{value_node.inspect})"
          end
          # Reassign `node` in case the child hook makes a modification
          if new_child_and_node.is_a?(Array)
            new_node = new_child_and_node[1]
          end
        end
        new_node
      end

      [
        Language::Nodes::Argument,
        Language::Nodes::Directive,
        Language::Nodes::DirectiveDefinition,
        Language::Nodes::DirectiveLocation,
        Language::Nodes::Document,
        Language::Nodes::Enum,
        Language::Nodes::EnumTypeDefinition,
        Language::Nodes::EnumTypeExtension,
        Language::Nodes::EnumValueDefinition,
        Language::Nodes::Field,
        Language::Nodes::FieldDefinition,
        Language::Nodes::FragmentDefinition,
        Language::Nodes::FragmentSpread,
        Language::Nodes::InlineFragment,
        Language::Nodes::InputObject,
        Language::Nodes::InputObjectTypeDefinition,
        Language::Nodes::InputObjectTypeExtension,
        Language::Nodes::InputValueDefinition,
        Language::Nodes::InterfaceTypeDefinition,
        Language::Nodes::InterfaceTypeExtension,
        Language::Nodes::ListType,
        Language::Nodes::NonNullType,
        Language::Nodes::NullValue,
        Language::Nodes::ObjectTypeDefinition,
        Language::Nodes::ObjectTypeExtension,
        Language::Nodes::OperationDefinition,
        Language::Nodes::ScalarTypeDefinition,
        Language::Nodes::ScalarTypeExtension,
        Language::Nodes::SchemaDefinition,
        Language::Nodes::SchemaExtension,
        Language::Nodes::TypeName,
        Language::Nodes::UnionTypeDefinition,
        Language::Nodes::UnionTypeExtension,
        Language::Nodes::VariableDefinition,
        Language::Nodes::VariableIdentifier,
      ].each do |ast_node_class|
        make_visit_methods(ast_node_class)
      end

      private

      def apply_modifications(node, parent, new_node_and_new_parent)
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
