module GraphQL
  module InternalRepresentation
    # Convert an AST into a tree of {InternalRepresentation::Node}s
    class Rewrite
      include GraphQL::Language

      # @return [Hash<String, InternalRepresentation::Node>] internal representation of each query root (operation, fragment)
      attr_reader :operations

      def initialize
        # { String => Node }
        @operations = {}
        @fragments = {}
        # [String...] fragments which don't have fragments inside them
        @independent_fragments = []
        # Stack<InternalRepresentation::Node>
        @nodes = []
        # { frag_name => [dependent_node, dependent_node]}
        @fragment_spreads = Hash.new { |h, k| h[k] = []}
        # [Nodes::Directive ... ] directive affecting the current scope
        @parent_directives = []
      end

      def validate(context)
        visitor = context.visitor
        visitor[Nodes::OperationDefinition].enter << -> (ast_node, prev_ast_node) {
          node = Node.new(
            return_type: context.type_definition.unwrap,
            ast_node: ast_node,
          )
          @nodes.push(node)
          @operations[ast_node.name] = node
        }
        visitor[Nodes::Field].enter << -> (ast_node, prev_ast_node) {
          parent_node = @nodes.last
          node_name = ast_node.alias || ast_node.name
          node = parent_node.children[node_name] ||= begin
            Node.new(
              return_type: context.type_definition && context.type_definition.unwrap,
              ast_node: ast_node,
              name: node_name,
              field: context.field_definition,
              directives: ast_node.directives + @parent_directives.flatten
            )
          end
          node.on_types << context.parent_type_definition.unwrap
          @nodes.push(node)
        }

        visitor[Nodes::InlineFragment].enter << -> (ast_node, prev_ast_node) {
          @parent_directives << ast_node.directives
        }

        visitor[Nodes::FragmentSpread].enter << -> (ast_node, prev_ast_node) {
          # Record _both sides_ of the dependency
          @nodes.last.spreads << ast_node
          @fragment_spreads[ast_node.name] << @nodes.last
        }

        visitor[Nodes::FragmentDefinition].enter << -> (ast_node, prev_ast_node) {
          node = Node.new(
            name: ast_node.name,
            return_type: context.type_definition,
            ast_node: ast_node,
          )
          @nodes.push(node)
          @fragments[ast_node.name] = node
        }

        visitor[Nodes::InlineFragment].leave  << -> (ast_node, prev_ast_node) {
          @parent_directives.pop
        }

        visitor[Nodes::FragmentDefinition].leave << -> (ast_node, prev_ast_node) {
          frag_node = @nodes.pop
          if frag_node.spreads.none?
            @independent_fragments << frag_node
          end
        }

        visitor[Nodes::OperationDefinition].leave << -> (ast_node, prev_ast_node) {
          @nodes.pop
        }

        visitor[Nodes::Field].leave << -> (ast_node, prev_ast_node) {
          @nodes.pop
        }

        visitor[Nodes::Document].leave << -> (ast_node, prev_ast_node) {
          # Resolve fragment dependencies. Start with fragments with no
          # dependencies and work along the spreads.
          while fragment_node = @independent_fragments.pop
            fragment_usages = @fragment_spreads[fragment_node.name]
            while dependent_node = fragment_usages.pop
              # remove self from dependent_node.spreads
              rejected_ast_nodes = dependent_node.spreads.select { |spr| spr.name == fragment_node.name }
              rejected_ast_nodes.each { |r_node| dependent_node.spreads.delete(r_node) }

              # resolve the dependency (merge into dependent node)
              deep_merge(dependent_node, fragment_node, rejected_ast_nodes.first.directives)

              if dependent_node.spreads.none? && dependent_node.ast_node.is_a?(Nodes::FragmentDefinition)
                @independent_fragments.push(dependent_node)
              end
            end
          end
        }
      end

      private

      def deep_merge(parent_node, fragment_node, directives)
        fragment_node.children.each do |name, child_node|
          deep_merge_child(parent_node, name, child_node, directives)
        end
      end

      def deep_merge_child(parent_node, name, node, extra_directives)
        child_node = parent_node.children[name] ||= node
        node.children.each do |merge_child_name, merge_child_node|
          deep_merge_child(child_node, merge_child_name, merge_child_node, [])
        end
        child_node.directives.push(*extra_directives)
      end
    end
  end
end
