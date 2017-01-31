module GraphQL
  module InternalRepresentation
    class Rewrite
      include GraphQL::Language

      NO_DIRECTIVES = [].freeze
      # @return [Hash<String, Node>] Roots of this query
      attr_reader :operations

      def initialize
        @operations = Hash.new {|h, k| h[k] = {} }
      end

      def validate(context)
        visitor = context.visitor
        query = context.query
        spread_parents = Hash.new { |h, k| h[k] = Set.new }
        nodes_stack = []
        scope_stack = []
        spreads_stack = []

        visit_defn = VisitDefinition.new(context, @operations, nodes_stack, scope_stack)
        visitor[Nodes::OperationDefinition].enter << visit_defn.method(:enter)
        visitor[Nodes::OperationDefinition].leave << visit_defn.method(:leave)
        visitor[Nodes::FragmentDefinition].enter << visit_defn.method(:enter)
        visitor[Nodes::FragmentDefinition].leave << visit_defn.method(:leave)

        visitor[Nodes::InlineFragment].enter << ->(ast_node, ast_parent) {
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
          spreads_stack.push(ast_node)
        }

        visitor[Nodes::InlineFragment].leave << ->(ast_node, ast_parent) {
          scope_stack.pop
          spreads_stack.pop
        }

        visitor[Nodes::Field].enter << ->(ast_node, ast_parent) {
          node_name = ast_node.alias || ast_node.name
          parent_nodes = nodes_stack.last
          next_nodes = []
          next_scope = Set.new
          applicable_scope = scope_stack.last
          applicable_spread = spreads_stack.last

          applicable_scope.each do |obj_type|
            # Can't use context.field_definition because that might be
            # a definition on an interface type
            field_defn = query.get_field(obj_type, ast_node.name)
            if field_defn.nil?
              # It's a non-existent field
            else
              field_return_type = field_defn.type
              each_type(query, field_return_type.unwrap) do |obj_type|
                next_scope.add(obj_type)
              end
              parent_nodes.each do |parent_node|
                node = parent_node.typed_children[obj_type][node_name] ||= Node.new(
                  name: node_name,
                  owner_type: obj_type,
                  query: query,
                )
                node.ast_nodes.push(ast_node)
                node.ast_directives.merge(ast_node.directives)
                node.definitions.add(field_defn)
                applicable_spread && node.ast_spreads.add(applicable_spread)
                next_nodes << node
              end
            end
          end
          nodes_stack.push(next_nodes)
          scope_stack.push(next_scope)
          spreads_stack.push(nil)
        }

        visitor[Nodes::Field].leave << ->(ast_node, ast_parent) {
          nodes_stack.pop
          scope_stack.pop
          spreads_stack.pop
        }

        visitor[Nodes::FragmentSpread].enter << ->(ast_node, ast_parent) {
          spread_parents[ast_node].merge(nodes_stack.last)
        }

        context.on_dependency_resolve do |defn_ast_node, spread_ast_nodes, frag_ast_node|
          frag_name = frag_ast_node.name
          spread_ast_nodes.each do |spread_ast_node|
            parent_nodes = spread_parents[spread_ast_node]
            parent_nodes.each do |parent_node|
              each_type(query, parent_node.return_type) do |obj_type|
                fragment_node = operations[obj_type][frag_name]
                if fragment_node
                  deep_merge_selections(query, parent_node, fragment_node, spread: spread_ast_node.node)
                end
              end
            end
          end
        end

        visitor[Nodes::Document].leave << ->(_n, _p) {
          # TODO: allow validation rules to access this
          # Post-validation: make some assertions about the rewritten query tree
          @operations.each do |obj_type, ops|
            ops.each do |op_name, op_node|
              # TODO fix this jank
              op_node.typed_children.each do |obj_type, children|
                children.each do |name, op_child_node|
                  each_node(op_child_node) do |node|
                    if node.definitions.size > 1
                      defn_names = node.definitions.map { |d| d.name }.sort.join(" or ")
                      msg = "Field '#{node.name}' has a field conflict: #{defn_names}?"
                      context.errors << GraphQL::StaticValidation::Message.new(msg, nodes: node.ast_nodes.to_a)
                    end

                    args = node.ast_nodes.map do |n|
                      n.arguments.reduce({}) do |memo, a|
                        arg_value = a.value
                        memo[a.name] = case arg_value
                          when GraphQL::Language::Nodes::VariableIdentifier
                            "$#{arg_value.name}"
                          when GraphQL::Language::Nodes::Enum
                            "#{arg_value.name}"
                          else
                            GraphQL::Language.serialize(arg_value)
                          end
                        memo
                      end
                    end
                    args.uniq!

                    if args.length != 1
                      context.errors <<  GraphQL::StaticValidation::Message.new("Field '#{node.name}' has an argument conflict: #{args.map{ |arg| GraphQL::Language.serialize(arg) }.join(" or ")}?", nodes: node.ast_nodes.to_a)
                    end
                  end
                end
              end
            end
          end
        }
      end

      def deep_merge_selections(query, prev_parent, new_parent, spread:)
        # p "prev parent: #{prev_parent.selections.map { |t, c| "#{t.name}: [#{c.keys.join(", ")}]"}.join(", ")}"
        # p "new  parent: #{new_parent.selections.map { |t, c| "#{t.name}: [#{c.keys.join(", ")}]"}.join(", ")}"
        new_parent.typed_children.each do |obj_type, new_fields|
          prev_fields = prev_parent.typed_children[obj_type]
          new_fields.each do |name, new_node|
            prev_node = prev_fields[name]
            # p "#{obj_type}.#{name} (prev? #{!!prev_node})"
            node = if prev_node
              prev_node.ast_nodes.concat(new_node.ast_nodes)
              prev_node.definitions.merge(new_node.definitions)
              prev_node.ast_directives.merge(new_node.ast_directives)
              deep_merge_selections(query, prev_node, new_node, spread: nil)
              prev_node
            else
              prev_fields[name] = new_node.deep_copy
            end
            # merge the inclusion context, if there is one
            spread && node.ast_spreads.add(spread)
          end
        end
      end

      def each_node(node)
        yield(node)
        node.typed_children.each do |obj_type, children|
          children.each do |name, node|
            each_node(node, &Proc.new)
          end
        end
      end

      def each_type(query, owner_type, &block)
        self.class.each_type(query, owner_type, &block)
      end

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

      class VisitDefinition
        def initialize(context, operations, nodes_stack, scope_stack)
          @context = context
          @query = context.query
          @operations = operations
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
            node = Node.new(
              name: defn_name,
              owner_type: obj_type,
              query: @query,
              ast_nodes: [ast_node],
              definitions: [OperationDefinitionProxy.new(obj_type)],
            )
            @operations[obj_type][defn_name] = node
            next_nodes << node
          end
          @nodes_stack.push(next_nodes)
          @scope_stack.push(next_scope)
        end

        def leave(ast_node, ast_parent)
          @nodes_stack.pop
          @scope_stack.pop
        end

        # Behaves enough like a field definition
        # to work in an irep node
        OperationDefinitionProxy = Struct.new(:type)
      end
    end
  end
end
