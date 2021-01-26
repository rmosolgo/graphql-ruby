# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    # While visiting an AST, build a normalized, flattened tree of {InternalRepresentation::Node}s.
    #
    # No unions or interfaces are present in this tree, only object types.
    #
    # Selections from the AST are attached to the object types they apply to.
    #
    # Inline fragments and fragment spreads are preserved in {InternalRepresentation::Node#ast_spreads},
    # where they can be used to check for the presence of directives. This might not be sufficient
    # for future directives, since the selections' grouping is lost.
    #
    # The rewritten query tree serves as the basis for the `FieldsWillMerge` validation.
    #
    module Rewrite
      include GraphQL::Language

      NO_DIRECTIVES = [].freeze

      # @return InternalRepresentation::Document
      attr_reader :rewrite_document

      def initialize(*)
        super
        @query = context.query
        @rewrite_document = InternalRepresentation::Document.new
        # Hash<Nodes::FragmentSpread => Set<InternalRepresentation::Node>>
        # A record of fragment spreads and the irep nodes that used them
        @rewrite_spread_parents = Hash.new { |h, k| h[k] = Set.new }
        # Hash<Nodes::FragmentSpread => Scope>
        @rewrite_spread_scopes = {}
        # Array<Set<InternalRepresentation::Node>>
        # The current point of the irep_tree during visitation
        @rewrite_nodes_stack = []
        # Array<Scope>
        @rewrite_scopes_stack = []
        @rewrite_skip_nodes = Set.new

        # Resolve fragment spreads.
        # Fragment definitions got their own irep trees during visitation.
        # Those nodes are spliced in verbatim (not copied), but this is OK
        # because fragments are resolved from the "bottom up", each fragment
        # can be shared between its usages.
        context.on_dependency_resolve do |defn_ast_node, spread_ast_nodes, frag_ast_node|
          frag_name = frag_ast_node.name
          fragment_node = @rewrite_document.fragment_definitions[frag_name]

          if fragment_node
            spread_ast_nodes.each do |spread_ast_node|
              parent_nodes = @rewrite_spread_parents[spread_ast_node]
              parent_scope = @rewrite_spread_scopes[spread_ast_node]
              parent_nodes.each do |parent_node|
                parent_node.deep_merge_node(fragment_node, scope: parent_scope, merge_self: false)
              end
            end
          end
        end
      end

      # @return [Hash<String, Node>] Roots of this query
      def operations
        GraphQL::Deprecation.warn "#{self.class}#operations is deprecated; use `document.operation_definitions` instead"
        @document.operation_definitions
      end

      def on_operation_definition(ast_node, parent)
        push_root_node(ast_node, @rewrite_document.operation_definitions) { super }
      end

      def on_fragment_definition(ast_node, parent)
        push_root_node(ast_node, @rewrite_document.fragment_definitions) { super }
      end

      def push_root_node(ast_node, definitions)
        # Either QueryType or the fragment type condition
        owner_type = context.type_definition
        defn_name = ast_node.name

        node = Node.new(
          parent: nil,
          name: defn_name,
          owner_type: owner_type,
          query: @query,
          ast_nodes: [ast_node],
          return_type: owner_type,
        )

        definitions[defn_name] = node
        @rewrite_scopes_stack.push(Scope.new(@query, owner_type))
        @rewrite_nodes_stack.push([node])
        yield
        @rewrite_nodes_stack.pop
        @rewrite_scopes_stack.pop
      end

      def on_inline_fragment(node, parent)
        # Inline fragments provide two things to the rewritten tree:
        # - They _may_ narrow the scope by their type condition
        # - They _may_ apply their directives to their children
        if skip?(node)
          @rewrite_skip_nodes.add(node)
        end

        if @rewrite_skip_nodes.empty?
          @rewrite_scopes_stack.push(@rewrite_scopes_stack.last.enter(context.type_definition))
        end

        super

        if @rewrite_skip_nodes.empty?
          @rewrite_scopes_stack.pop
        end

        if @rewrite_skip_nodes.include?(node)
          @rewrite_skip_nodes.delete(node)
        end
      end

      def on_field(ast_node, ast_parent)
        if skip?(ast_node)
          @rewrite_skip_nodes.add(ast_node)
        end

        if @rewrite_skip_nodes.empty?
          node_name = ast_node.alias || ast_node.name
          parent_nodes = @rewrite_nodes_stack.last
          next_nodes = []

          field_defn = context.field_definition
          if field_defn.nil?
            # It's a non-existent field
            new_scope = nil
          else
            field_return_type = field_defn.type
            @rewrite_scopes_stack.last.each do |scope_type|
              parent_nodes.each do |parent_node|
                node = parent_node.scoped_children[scope_type][node_name] ||= Node.new(
                  parent: parent_node,
                  name: node_name,
                  owner_type: scope_type,
                  query: @query,
                  return_type: field_return_type,
                )
                node.ast_nodes << ast_node
                node.definitions << field_defn
                next_nodes << node
              end
            end
            new_scope = Scope.new(@query, field_return_type.unwrap)
          end

          @rewrite_nodes_stack.push(next_nodes)
          @rewrite_scopes_stack.push(new_scope)
        end

        super

        if @rewrite_skip_nodes.empty?
          @rewrite_nodes_stack.pop
          @rewrite_scopes_stack.pop
        end

        if @rewrite_skip_nodes.include?(ast_node)
          @rewrite_skip_nodes.delete(ast_node)
        end
      end

      def on_fragment_spread(ast_node, ast_parent)
        if @rewrite_skip_nodes.empty? && !skip?(ast_node)
          # Register the irep nodes that depend on this AST node:
          @rewrite_spread_parents[ast_node].merge(@rewrite_nodes_stack.last)
          @rewrite_spread_scopes[ast_node] = @rewrite_scopes_stack.last
        end
        super
      end

      def skip?(ast_node)
        dir = ast_node.directives
        dir.any? && !GraphQL::Execution::DirectiveChecks.include?(dir, @query)
      end
    end
  end
end
