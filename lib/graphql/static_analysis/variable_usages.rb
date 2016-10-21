module GraphQL
  module StaticAnalysis
    # Ride along with a visitor, recording where variables are defined and used.
    # Then, based on a provided dependency map, flatten usages to where they were
    # actually used.
    class VariableUsages
      def self.mount(visitor)
        variable_usages = self.new
        variable_usages.mount(visitor)
        variable_usages
      end

      def initialize
        @definitions = Hash.new do |hash, key|
          hash[key] = {
            defined: Hash.new { |h, k| h[k] = [] },
            used:    Hash.new { |h, k| h[k] = [] },
          }
        end

        @current_definition = nil
      end

      def mount(visitor)
        visitor[GraphQL::Language::Nodes::FragmentDefinition] << -> (node, prev_node) {
          @current_definition = @definitions[node]
        }

        visitor[GraphQL::Language::Nodes::FragmentDefinition].leave << -> (node, prev_node) {
          @current_definition = nil
        }

        visitor[GraphQL::Language::Nodes::VariableDefinition] << -> (node, prev_node) {
          @current_definition[:defined][node.name] << node
        }

        visitor[GraphQL::Language::Nodes::VariableIdentifier] << -> (node, prev_node) {
          @current_definition[:used][node.name] << node
        }

        visitor[GraphQL::Language::Nodes::OperationDefinition] << -> (node, prev_node) {
          @current_definition = @definitions[node]
        }

        visitor[GraphQL::Language::Nodes::OperationDefinition].leave << -> (node, prev_node) {
          @current_definition = nil
        }
      end


      # Based on `dependencies`, for each operation definition:
      # - Find variable usages, and group them by name
      # - Find variable definitions and group them by name
      # @example A usage hash
      #  {
      #    operation_definition_node => {
      #      used: {
      #        "var_name" => [usage_node, usage_node],
      #      },
      #      defined: {
      #         "var_name" => [defn_node],
      #      }
      #    }
      #  }
      # Then return them in a map of `node => {used:, defined:}`.
      # @return [Hash<GraphQL::Language::Nodes::OperationDefintion => Hash>] map AST nodes to {used:, defined:} hashes
      def usages(dependencies:)

        usage_map = {}
        @definitions.each do |ast_op_defn, variables|
          if !ast_op_defn.is_a?(GraphQL::Language::Nodes::OperationDefinition)
            next
          end

          # We have to know usages in fragments, too, so get this node's dependencies:
          dependency_nodes = dependencies[ast_op_defn]

          # Now, get all usages in this node and its dependencies
          all_nodes = [ast_op_defn].concat(dependency_nodes)

          all_usages = Hash.new { |h, k| h[k] = [] }

          all_nodes.each do |ast_node|
            @definitions[ast_node][:used].each do |name, usage_nodes|
              all_usages[name].concat(usage_nodes)
            end
          end

          usage_map[ast_op_defn] = {
            used: all_usages,
            defined: variables[:defined],
          }
        end

        usage_map
      end
    end
  end
end
