module GraphQL
  module StaticAnalysis
    module Rules
      # Implements some validations from the GraphQL spec:
      #
      # - Argument Uniqueness
      # - Input Object Field Uniqueness
      class ArgumentsAreUnique
        attr_reader :errors

        def initialize(analysis)
          visitor = analysis.visitor
          @errors = []

          # A stack of nodes that have arguments
          @node_stack = []

          push_node_data = -> (node, prev_node) {
            if node.arguments.any?
              @node_stack << {
                parent_node: node,
                arguments: Hash.new { |h, k| h[k] = [] },
              }
            end
          }

          check_argument_uniqueness = -> (node, prev_node) {
            if node.arguments.any?
              node_data = @node_stack.pop
              node_data[:arguments].each do |arg_name, arg_nodes|
                if arg_nodes.length > 1
                  @errors << AnalysisError.new(
                    "Arguments must be unique, but \"#{arg_name}\" is provided #{arg_nodes.length} times",
                    nodes: arg_nodes,
                  )
                end
              end
            end
          }

          visitor[GraphQL::Language::Nodes::Argument]  << -> (node, prev_node) {
            @node_stack.last[:arguments][node.name] << node
          }

          visitor[GraphQL::Language::Nodes::Field]        << push_node_data
          visitor[GraphQL::Language::Nodes::Directive]    << push_node_data
          visitor[GraphQL::Language::Nodes::InputObject]  << push_node_data

          visitor[GraphQL::Language::Nodes::Field].leave        << check_argument_uniqueness
          visitor[GraphQL::Language::Nodes::Directive].leave    << check_argument_uniqueness
          visitor[GraphQL::Language::Nodes::InputObject].leave  << check_argument_uniqueness
        end
      end
    end
  end
end
