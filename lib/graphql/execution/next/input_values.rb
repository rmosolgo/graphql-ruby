# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
      class InputValues
        def initialize(context:)
          @context = context
          @variables = context.query.variables
        end

        def coerce_argument_values(owner_defn, owner_node)
          arg_defns = @context.types.arguments(owner_defn)
          argument_nodes = owner_node.arguments
          argument_values = {}

          arg_defns.each do |argument_definition|
            arg_ruby_key = argument_definition.keyword
            arg_graphql_key = argument_definition.graphql_name
            arg_node = argument_nodes.find { |a| a.name == arg_graphql_key }
            if arg_node.nil?
              if argument_definition.default_value?
                argument_values[arg_ruby_key] = argument_definition.default_value # TODO coerce
              elsif argument_definition.type.non_null?
                # TODO Add an error
              end
            else
              arg_value = arg_node.value
              if arg_value.is_a?(Language::Nodes::VariableIdentifier)
                if @variables.key?(arg_value.name)
                  # Use variable value

                else
                  var_sym_key = arg_value.name.to_sym
                  if @variables.key?(var_sym_key)
                    # Use variable value
                  elsif argument_definition.default_value?
                    argument_values[arg_ruby_key] = argument_definition.default_value # TODO coerce
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
