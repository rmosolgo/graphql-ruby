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

      def argument_values(owner_defn, argument_nodes, field_resolve_step)
        arg_defns = @query.types.arguments(owner_defn)
        argument_values = {}

        arg_defns.each do |argument_definition|
          arg_ruby_key = argument_definition.keyword
          arg_graphql_key = argument_definition.graphql_name
          arg_node = argument_nodes.find { |a| a.name == arg_graphql_key }
          if arg_node.nil?
            if argument_definition.default_value?
              argument_value(argument_values, arg_ruby_key, argument_definition, argument_definition.default_value, nil, field_resolve_step)
            elsif argument_definition.type.non_null?
              # TODO Add an error
            end
          else
            argument_value(argument_values, arg_ruby_key, argument_definition, arg_node.value, nil, field_resolve_step)
          end
        end

        argument_values
      end


      private

      def argument_value(argument_values, arg_ruby_key, argument_definition, arg_value, override_type, field_resolve_step)
        treat_as_type = override_type || argument_definition.type
        if treat_as_type.non_null?
          treat_as_type = treat_as_type.unwrap
        end

        arg_value = case arg_value
        when Language::Nodes::AbstractNode
          case arg_value
          when Language::Nodes::VariableIdentifier
            variable_values[arg_value.name]
          when Language::Nodes::Enum
            treat_as_type.coerce_input(arg_value.name, @query.context)
          when Language::Nodes::NullValue
            nil
          when Language::Nodes::InputObject
            self.argument_values(treat_as_type, arg_value.arguments, field_resolve_step)
          end
        when Array
          inner_t = treat_as_type.unwrap
          arg_value.map { |inner_v| argument_value(argument_values, arg_ruby_key, argument_definition, inner_v, inner_t, field_resolve_step)}
        else
          arg_value # todo coerce
        end

        if argument_definition.loads && arg_value && override_type.nil?
          field_defn = field_resolve_step.field_definition
          load_receiver = if (r = field_defn.resolver)
            r.new(field: field_defn, context: @query.context, object: nil)
          else
            field_defn
          end

          loads_step = LoadArgumentStep.new(
            field_resolve_step: field_resolve_step,
            load_receiver: load_receiver,
            argument_value: arg_value,
            argument_definition: argument_definition,
            arguments: argument_values,
            argument_key: arg_ruby_key,
          )
          ps = field_resolve_step.pending_steps ||= []
          ps.push(loads_step)
          @runner.add_step(loads_step)
        else
          argument_values[arg_ruby_key] = arg_value
        end
      end
    end
  end
end
