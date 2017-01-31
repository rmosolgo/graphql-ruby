# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    # Traverse a re-written query tree, calling handlers for each node
    module Visit
      module_function
      def visit_each_node(definitions, handlers)
        # Post-validation: make some assertions about the rewritten query tree
        definitions.each do |obj_type, ops|
          ops.each do |op_name, op_node|
            # Skip fragments, since they've been merged into the operations already
            if op_node.ast_nodes.first.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
              next
            end

            # Yield each node to listeners which were attached by validators
            op_node.typed_children.each do |obj_type, children|
              children.each do |name, op_child_node|
                each_node(op_child_node) do |node|
                  for h in handlers
                    h.call(node)
                  end
                end
              end
            end
          end
        end
      end

      # Traverse a node in a rewritten query tree,
      # visiting the node itself and each of its typed children.
      def each_node(node)
        yield(node)
        if node.typed_children.any?
          visit_block = Proc.new
          node.typed_children.each do |obj_type, children|
            children.each do |name, node|
              each_node(node, &visit_block)
            end
          end
        end
      end
    end
  end
end
