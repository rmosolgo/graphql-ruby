module GraphQL
  module Language
    module TraceVisitor
      module_function

      # When `visitor` traverses the document, keep track of the
      # human-friendly stack and assign a `trace` to each node.
      # @param visitor [GraphQL::Language::Visitor]
      # @param name_stack [Array<String>] Array will be mutated (strings pushed and popped)
      # @return [void]
      def attach_enter(visitor, name_stack)

        visitor[Nodes::OperationDefinition].enter << -> (node, _p) {
          name_stack.push("#{node.operation_type}#{node.name ? " #{node.name}" : ""}")
        }

        visitor[Nodes::Field].enter << -> (node, _p) {
          name_stack.push(node.alias || node.name)
        }

        visitor[Nodes::FragmentDefinition].enter << -> (node, _p) {
          name_stack.push("fragment #{node.name}")
        }

        visitor[Nodes::InlineFragment].enter << -> (node, _p) {
          name_stack.push("...#{node.type ? " on #{node.type}" : ""}")
        }

        visitor[Nodes::FragmentSpread].enter << -> (node, _p) {
          name_stack.push("...#{node.name}")
        }

        visitor[Nodes::Argument].enter << -> (node, _p) {
          name_stack.push(node.name)
        }
      end


      def attach_leave(visitor, name_stack)
        pop_stack = -> (_n, _p) { name_stack.pop }
        visitor[Nodes::OperationDefinition].leave << pop_stack
        visitor[Nodes::Field].leave << pop_stack
        visitor[Nodes::FragmentDefinition].leave << pop_stack
        visitor[Nodes::InlineFragment].leave << pop_stack
        visitor[Nodes::FragmentSpread].leave << pop_stack
        visitor[Nodes::Argument].leave << pop_stack
      end
    end
  end
end
