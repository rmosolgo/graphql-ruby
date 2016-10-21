module GraphQL
  module StaticAnalysis
    # Group top-level definitions by name
    class DefinitionNames
      def self.mount(visitor)
        op_names = self.new
        op_names.mount(visitor)
        op_names
      end

      attr_reader :anonymous_operations, :named_operations, :fragment_definitions

      def initialize
        @anonymous_operations = []
        @named_operations = Hash.new { |h, k| h[k] = [] }
        @fragment_definitions = Hash.new { |h, k| h[k] = [] }
      end

      def mount(visitor)
        visitor[GraphQL::Language::Nodes::OperationDefinition] << -> (node, prev_node) {
          if node.name.nil?
            @anonymous_operations << node
          else
            @named_operations[node.name] << node
          end
        }

        visitor[GraphQL::Language::Nodes::FragmentDefinition] << -> (node, prev_node) {
          @fragment_definitions[node.name] << node
        }
      end
    end
  end
end
