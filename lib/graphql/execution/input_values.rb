# frozen_string_literal: true
module GraphQL
  module Execution
    class InputValues
      def initialize(query, runner)
        @query = query
        @runner = runner
        @variables = query.variables
        @variable_values = nil
      end

      def variable_values
        @variable_values ||= begin
          variable_nodes = @query.selected_operation.variables
          if variable_nodes.empty?
            EmptyObjects::EMPTY_HASH
          else
            raw_values = @query.provided_variables
            values = {}
            variable_nodes.each do |var_node|
              # TODO coerce somewhere
              if raw_values.key?(var_node.name)
                values[var_node.name] = raw_values[var_node.name] # Todo check Symbol?
              elsif !var_node.default_value.nil?
                values[var_node.name] = var_node.default_value
              end
            end
            values
          end
        end
      end

      def argument_values(owner_defn, argument_nodes, pending_steps)
        arg_defns = @query.types.arguments(owner_defn)
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
            argument_values[arg_ruby_key] = argument_value(arg_node.value, argument_definition.type, pending_steps)
          end
        end

        argument_values
      end


      private

      def argument_value(arg_value, argument_type, pending_steps)
        if argument_type.non_null?
          argument_type = argument_type.unwrap
        end

        case arg_value
        when Language::Nodes::AbstractNode
          case arg_value
          when Language::Nodes::VariableIdentifier
            variable_values[arg_value.name]
          when Language::Nodes::Enum
            argument_type.coerce_input(arg_value.name, @query.context)
          when Language::Nodes::NullValue
            nil
          when Language::Nodes::InputObject
            self.argument_values(argument_type, arg_value.arguments, pending_steps)
          end
        when Array
          inner_t = argument_type.unwrap
          arg_value.map { |inner_v| argument_value(inner_v, inner_t, pending_steps)}
        else
          arg_value # todo coerce
        end
      end
    end
  end
end
