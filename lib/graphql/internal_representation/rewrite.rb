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
    class Rewrite
      include GraphQL::Language

      NO_DIRECTIVES = [].freeze

      # @return [Hash<String, Node>] Roots of this query
      attr_reader :operations

      def initialize
        @operations = {}
      end

      def validate(context)
        visitor = context.visitor
        query = context.query
        # Hash<Nodes::FragmentSpread => Set<InternalRepresentation::Node>>
        # A record of fragment spreads and the irep nodes that used them
        spread_parents = Hash.new { |h, k| h[k] = Set.new }
        # Array<Set<InternalRepresentation::Node>>
        # The current point of the irep_tree during visitation
        nodes_stack = []
        # Array<Set<GraphQL::ObjectType>>
        # Object types that the current point of the irep_tree applies to
        scope_stack = []
        fragment_definitions = {}
        skip_nodes = Set.new

        visit_op = VisitDefinition.new(context, @operations, nodes_stack, scope_stack)
        visitor[Nodes::OperationDefinition].enter << visit_op.method(:enter)
        visitor[Nodes::OperationDefinition].leave << visit_op.method(:leave)

        visit_frag = VisitDefinition.new(context, fragment_definitions, nodes_stack, scope_stack)
        visitor[Nodes::FragmentDefinition].enter << visit_frag.method(:enter)
        visitor[Nodes::FragmentDefinition].leave << visit_frag.method(:leave)

        visitor[Nodes::InlineFragment].enter << ->(ast_node, ast_parent) {
          # Inline fragments provide two things to the rewritten tree:
          # - They _may_ narrow the scope by their type condition
          # - They _may_ apply their directives to their children

          if skip?(ast_node, query)
            skip_nodes.add(ast_node)
          end

          if skip_nodes.none?
            next_scope = Set.new
            prev_scope = scope_stack.last
            each_type(query, context.type_definition) do |obj_type|
              # What this fragment can apply to is also determined by
              # the scope around it (it can't widen the scope)
              if prev_scope.include?(obj_type)
                next_scope.add(obj_type)
              end
            end
            scope_stack.push(next_scope)
          end
        }

        visitor[Nodes::InlineFragment].leave << ->(ast_node, ast_parent) {
          if skip_nodes.none?
            scope_stack.pop
          end

          if skip_nodes.include?(ast_node)
            skip_nodes.delete(ast_node)
          end
        }

        visitor[Nodes::Field].enter << ->(ast_node, ast_parent) {
          if skip?(ast_node, query)
            skip_nodes.add(ast_node)
          end

          if skip_nodes.none?
            node_name = ast_node.alias || ast_node.name
            parent_nodes = nodes_stack.last
            next_nodes = []
            next_scope = Set.new
            applicable_scope = scope_stack.last

            applicable_scope.each do |obj_type|
              # Can't use context.field_definition because that might be
              # a definition on an interface type
              field_defn = query.get_field(obj_type, ast_node.name)
              if field_defn.nil?
                # It's a non-existent field
              else
                field_return_type = field_defn.type.unwrap
                each_type(query, field_return_type) do |obj_type|
                  next_scope.add(obj_type)
                end
                parent_nodes.each do |parent_node|
                  node = parent_node.typed_children[obj_type][node_name] ||= Node.new(
                    parent: parent_node,
                    name: node_name,
                    owner_type: obj_type,
                    query: query,
                    return_type: field_return_type,
                  )
                  node.ast_nodes.add(ast_node)
                  node.definitions.add(field_defn)
                  next_nodes << node
                end
              end
            end
            nodes_stack.push(next_nodes)
            scope_stack.push(next_scope)
          end
        }

        visitor[Nodes::Field].leave << ->(ast_node, ast_parent) {
          if skip_nodes.none?
            nodes_stack.pop
            scope_stack.pop
          end

          if skip_nodes.include?(ast_node)
            skip_nodes.delete(ast_node)
          end
        }

        visitor[Nodes::FragmentSpread].enter << ->(ast_node, ast_parent) {
          if skip_nodes.none? && !skip?(ast_node, query)
            # Register the irep nodes that depend on this AST node:
            spread_parents[ast_node].merge(nodes_stack.last)
          end
        }

        # Resolve fragment spreads.
        # Fragment definitions got their own irep trees during visitation.
        # Those nodes are spliced in verbatim (not copied), but this is OK
        # because fragments are resolved from the "bottom up", each fragment
        # can be shared between its usages.
        context.on_dependency_resolve do |defn_ast_node, spread_ast_nodes, frag_ast_node|
          frag_name = frag_ast_node.name
          spread_ast_nodes.each do |spread_ast_node|
            parent_nodes = spread_parents[spread_ast_node]
            parent_nodes.each do |parent_node|
              fragment_node = fragment_definitions[frag_name]
              if fragment_node
                deep_merge_selections(query, parent_node, fragment_node)
              end
            end
          end
        end
      end

      # Merge selections from `new_parent` into `prev_parent`.
      # If `new_parent` came from a spread in the AST, it's present as `spread`.
      # Selections are merged in place, not copied.
      def deep_merge_selections(query, prev_parent, new_parent)
        new_parent.typed_children.each do |obj_type, new_fields|
          prev_fields = prev_parent.typed_children[obj_type]
          new_fields.each do |name, new_node|
            prev_node = prev_fields[name]
            if prev_node
              prev_node.ast_nodes.merge(new_node.ast_nodes)
              prev_node.definitions.merge(new_node.definitions)
              deep_merge_selections(query, prev_node, new_node)
            else
              prev_fields[name] = new_node
            end
          end
        end
      end

      # @see {.each_type}
      def each_type(query, owner_type, &block)
        self.class.each_type(query, owner_type, &block)
      end

      # Call the block for each of `owner_type`'s possible types
      def self.each_type(query, owner_type)
        case owner_type
        when GraphQL::ObjectType, GraphQL::ScalarType, GraphQL::EnumType
          yield(owner_type)
        when GraphQL::UnionType, GraphQL::InterfaceType
          query.possible_types(owner_type).each(&Proc.new)
        when GraphQL::InputObjectType, nil
          # this is an error, don't give 'em nothin
        else
          raise "Unexpected owner type: #{owner_type.inspect}"
        end
      end

      def skip?(ast_node, query)
        dir = ast_node.directives
        dir.any? && !GraphQL::Execution::DirectiveChecks.include?(dir, query)
      end

      class VisitDefinition
        def initialize(context, definitions, nodes_stack, scope_stack)
          @context = context
          @query = context.query
          @definitions = definitions
          @nodes_stack = nodes_stack
          @scope_stack = scope_stack
        end

        def enter(ast_node, ast_parent)
          # Either QueryType or the fragment type condition
          owner_type = @context.type_definition && @context.type_definition.unwrap
          next_nodes = []
          next_scope = Set.new
          defn_name = ast_node.name
          Rewrite.each_type(@query, owner_type) do |obj_type|
            next_scope.add(obj_type)
          end

          node = Node.new(
            parent: nil,
            name: defn_name,
            owner_type: owner_type,
            query: @query,
            ast_nodes: Set.new([ast_node]),
            return_type: owner_type,
          )
          @definitions[defn_name] = node
          next_nodes << node

          @nodes_stack.push(next_nodes)
          @scope_stack.push(next_scope)
        end

        def leave(ast_node, ast_parent)
          @nodes_stack.pop
          @scope_stack.pop
        end
      end
    end
  end
end
