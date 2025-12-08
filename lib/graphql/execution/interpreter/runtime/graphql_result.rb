# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class Runtime
        module GraphQLResult
          include Runtime::Step
          def initialize(runtime_instance, result_name, result_type, application_value, parent_result, is_non_null_in_parent, selections, is_eager, ast_node, graphql_arguments, graphql_field) # rubocop:disable Metrics/ParameterLists
            @runtime = runtime_instance
            @ast_node = ast_node
            @graphql_arguments = graphql_arguments
            @graphql_field = graphql_field
            @graphql_parent = parent_result
            @graphql_application_value = application_value
            @graphql_result_type = result_type
            if parent_result && parent_result.graphql_dead
              @graphql_dead = true
            end
            @graphql_result_name = result_name
            @graphql_is_non_null_in_parent = is_non_null_in_parent
            # Jump through some hoops to avoid creating this duplicate storage if at all possible.
            @graphql_metadata = nil
            @graphql_selections = selections
            @graphql_is_eager = is_eager
            @base_path = nil
            @graphql_depth = nil
          end

          # TODO test full path in Partial
          attr_writer :base_path

          attr_reader :graphql_dead

          def current_result
            self
          end

          def current_result_name
            nil
          end

          def path
            @path ||= build_path([])
          end

          def build_path(path_array)
            graphql_result_name && path_array.unshift(graphql_result_name)
            if @graphql_parent
              @graphql_parent.build_path(path_array)
            elsif @base_path
              @base_path + path_array
            else
              path_array
            end
          end

          def depth
            @depth ||= if @graphql_parent
              @graphql_parent.depth + 1
            else
              1
            end
          end

          attr_reader :graphql_parent, :graphql_result_name, :graphql_is_non_null_in_parent,
            :graphql_application_value, :graphql_result_type, :graphql_selections, :graphql_is_eager, :ast_node, :graphql_arguments, :graphql_field

          attr_reader :step

          # @return [Hash] Plain-Ruby result data (`@graphql_metadata` contains Result wrapper objects)
          attr_accessor :graphql_result_data
        end
      end
    end
  end
end
