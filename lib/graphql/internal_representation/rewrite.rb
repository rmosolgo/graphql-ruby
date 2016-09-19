module GraphQL
  module InternalRepresentation
    # Convert an AST into a tree of {InternalRepresentation::Node}s
    #
    # This rides along with {StaticValidation}, building a tree of nodes.
    #
    # However, if any errors occurred during validation, the resulting tree is bogus.
    #  (For example, `nil` could have been pushed instead of a type.)
    class Rewrite
      include GraphQL::Language

      # @return [Hash<String => InternalRepresentation::Node>] internal representation of each query root (operation, fragment)
      attr_reader :operations

      def initialize
        # { String => Node } Tracks the roots of the query
        @operations = {}
        @fragments = {}
        # [String...] fragments which don't have fragments inside them
        @independent_fragments = []
        # Tracks the current node during traversal
        # Stack<InternalRepresentation::Node>
        @nodes = []
        # This tracks dependencies from fragment to Node where it was used
        # { frag_name => [dependent_node, dependent_node]}
        @fragment_spreads = Hash.new { |h, k| h[k] = []}
        # [Nodes::Directive ... ] directive affecting the current scope
        @parent_directives = []
      end

      def validate(context)
        visitor = context.visitor

        visitor[Nodes::OperationDefinition].enter << -> (ast_node, prev_ast_node) {
          node = Node.new(
            return_type: context.type_definition && context.type_definition.unwrap,
            ast_node: ast_node,
            name: ast_node.name,
            parent: nil,
          )
          @nodes.push(node)
          @operations[ast_node.name] = node
        }

        visitor[Nodes::Field].enter << -> (ast_node, prev_ast_node) {
          parent_node = @nodes.last
          node_name = ast_node.alias || ast_node.name
          # This node might not be novel, eg inside an inline fragment
          # but it could contain new type information, which is captured below.
          # (StaticValidation ensures that merging fields is fair game)
          node = parent_node.children[node_name] ||= begin
            Node.new(
              return_type: context.type_definition && context.type_definition.unwrap,
              ast_node: ast_node,
              name: node_name,
              definition_name: ast_node.name,
              parent: parent_node,
            )
          end
          object_type = context.parent_type_definition.unwrap
          node.definitions[object_type] = context.field_definition
          @nodes.push(node)
          @parent_directives.push([])
        }

        visitor[Nodes::InlineFragment].enter << -> (ast_node, prev_ast_node) {
          @parent_directives.push([])
        }

        visitor[Nodes::Directive].enter << -> (ast_node, prev_ast_node) {
          # It could be a query error where a directive is somewhere it shouldn't be
          if @parent_directives.any?
            @parent_directives.last << Node.new(
              name: ast_node.name,
              definition_name: ast_node.name,
              ast_node: ast_node,
              definitions: [context.directive_definition],
              # This isn't used, the directive may have many parents in the case of inline fragment
              parent: nil,
            )
          end
        }

        visitor[Nodes::FragmentSpread].enter << -> (ast_node, prev_ast_node) {
          parent_node = @nodes.last
          # Record _both sides_ of the dependency
          spread_node = Node.new(
            parent: parent_node,
            name: ast_node.name,
            ast_node: ast_node,
          )
          # The parent node has a reference to the fragment
          parent_node.spreads.push(spread_node)
          # And keep a reference from the fragment to the parent node
          @fragment_spreads[ast_node.name].push(parent_node)
          @nodes.push(spread_node)
          @parent_directives.push([])
        }

        visitor[Nodes::FragmentDefinition].enter << -> (ast_node, prev_ast_node) {
          node = Node.new(
            parent: nil,
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

        visitor[Nodes::FragmentSpread].leave  << -> (ast_node, prev_ast_node) {
          # Capture any directives that apply to this spread
          # so that they can be applied to fields when
          # the fragment is merged in later
          spread_node = @nodes.pop
          spread_node.directives.merge(@parent_directives.flatten)
          @parent_directives.pop
        }

        visitor[Nodes::FragmentDefinition].leave << -> (ast_node, prev_ast_node) {
          # This fragment doesn't depend on any others,
          # we should save it as the starting point for dependency resolution
          frag_node = @nodes.pop
          if !any_fragment_spreads?(frag_node)
            @independent_fragments << frag_node
          end
        }

        visitor[Nodes::OperationDefinition].leave << -> (ast_node, prev_ast_node) {
          @nodes.pop
        }

        visitor[Nodes::Field].leave << -> (ast_node, prev_ast_node) {
          # Pop this field's node
          # and record any directives that were visited
          # during this field & before it (eg, inline fragments)
          field_node = @nodes.pop
          field_node.directives.merge(@parent_directives.flatten)
          @parent_directives.pop
        }

        visitor[Nodes::Document].leave << -> (ast_node, prev_ast_node) {
          # Resolve fragment dependencies. Start with fragments with no
          # dependencies and work along the spreads.
          while fragment_node = @independent_fragments.pop
            fragment_usages = @fragment_spreads[fragment_node.name]
            while dependent_node = fragment_usages.pop
              # remove self from dependent_node.spreads
              rejected_spread_nodes = dependent_node.spreads.select { |spr| spr.name == fragment_node.name }
              rejected_spread_nodes.each { |r_node| dependent_node.spreads.delete(r_node) }

              # resolve the dependency (merge into dependent node)
              deep_merge(dependent_node, fragment_node, rejected_spread_nodes.first.directives)
              owner = dependent_node.owner
              if owner.ast_node.is_a?(Nodes::FragmentDefinition) && !any_fragment_spreads?(owner)
                @independent_fragments.push(owner)
              end
            end
          end
        }
      end

      private

      # Merge the chilren from `fragment_node` into `parent_node`. Merge `directives` into each of those fields.
      def deep_merge(parent_node, fragment_node, directives)
        fragment_node.children.each do |name, child_node|
          deep_merge_child(parent_node, name, child_node, directives)
        end
      end

      # Merge `node` into `parent_node`'s children, as `name`, applying `extra_directives`
      def deep_merge_child(parent_node, name, node, extra_directives)
        child_node = parent_node.children[name] ||= node.dup
        child_node.definitions.merge!(node.definitions)
        node.children.each do |merge_child_name, merge_child_node|
          deep_merge_child(child_node, merge_child_name, merge_child_node, [])
        end
        child_node.directives.merge(extra_directives)
      end

      # return true if node or _any_ children have a fragment spread
      def any_fragment_spreads?(node)
        node.spreads.any? || node.children.any? { |name, node| any_fragment_spreads?(node) }
      end
    end
  end
end
