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
              var_ast_value = if raw_values.key?(var_node.name)
                raw_values[var_node.name]
              elsif raw_values.key?(sym_name = var_node.name.to_sym)
                raw_values[sym_name]
              elsif !var_node.default_value.nil?
                var_node.default_value
              else
                nil
              end

              var_type = @runner.schema.type_from_ast(var_node.type, context: @query.context)
              values[var_node.name] = variable_value(var_ast_value, var_type)
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

      def variable_value(value, type)
        if type.non_null?
          type = type.of_type
        end

        if value.nil?
          nil
        elsif type.list?
          inner_type = type.of_type
          if value.is_a?(Array)
            value.map { |v| variable_value(v, inner_type) }.freeze
          else
            [variable_value(value, inner_type)].freeze
          end
        elsif type.kind.input_object?
          coerced_obj = {}

          @query.types.arguments(type).each do |arg|
            arg_key = arg.keyword
            if value.key?(arg.graphql_name)
              arg_value = value[arg.graphql_name]
            elsif value.key?(sym_name = arg.graphql_name.to_sym)
              arg_value = value[sym_name]
            elsif arg.default_value?
              coerced_obj[arg_key] = arg.default_value # todo coerce
              next
            else
              next
            end

            coerced_obj[arg_key] = variable_value(arg_value, arg.type)
          end

          coerced_obj.freeze
        elsif type.kind.leaf?
          result = begin
            type.coerce_input(value, @query.context)
          rescue GraphQL::ExecutionError => e
            e
          end

          result
        else
          raise InputCoercionError, "Unexpected input type: #{type.graphql_name}."
        end
      end

      def argument_value(argument_values, argument_key, argument_definition, arg_value, override_type, field_resolve_step)
        treat_as_type = override_type || argument_definition.type
        if treat_as_type.non_null?
          treat_as_type = treat_as_type.of_type
        end

        arg_value = value_from_ast(arg_value, treat_as_type)

        if treat_as_type.kind.list? && !arg_value.nil?
          inner_t = treat_as_type.unwrap
          arg_value = if arg_value.is_a?(Array)
            values = Array.new(arg_value.size)
            arg_value.each_with_index { |inner_v, idx| argument_value(values, idx, argument_definition, inner_v, inner_t, field_resolve_step)}
            values
          else
            values = [nil]
            argument_value(values, 0, argument_definition, arg_value, inner_t, field_resolve_step)
            values
          end
        end

        if override_type.nil? # only on root arguments, not list elements
          arg_value = begin
            begin
              argument_definition.prepare_value(nil, arg_value, context: @query.context)
            rescue StandardError => err
              @runner.schema.handle_or_reraise(@query.context, err)
            end
          rescue GraphQL::ExecutionError => exec_err
            exec_err
          end
        end

        if arg_value && override_type.nil? && (argument_definition.loads || treat_as_type.kind.input_object?)
          loads_recursively(argument_values, argument_key, argument_definition, arg_value, field_resolve_step)
        else
          argument_values[argument_key] = arg_value
        end
        nil
      end

      def loads_recursively(argument_values, argument_key, argument_definition, arg_value, field_resolve_step)
        if (input_obj_type = argument_definition.type.unwrap).kind.input_object?
          arg_defns = @query.types.arguments(input_obj_type)
          loadable_arg_value = argument_values[argument_key] = arg_value.dup
          arg_defns.each do |inner_arg_defn|
            inner_arg_key = inner_arg_defn.keyword
            inner_arg_value = loadable_arg_value[inner_arg_key]
            if !inner_arg_value.nil?
              loads_recursively(loadable_arg_value, inner_arg_key, inner_arg_defn, inner_arg_value, field_resolve_step)
            end
          end
        elsif argument_definition.loads
          field_defn = field_resolve_step.field_definition
          load_receiver = if (r = field_defn.resolver)
            r.new(field: field_defn, context: @query.context, object: nil)
          else
            field_defn
          end
          ps = field_resolve_step.pending_steps ||= []

          if argument_definition.type.list?
            results = Array.new(arg_value.size, nil)
            argument_values[argument_key] = results
            arg_value.each_with_index do |inner_v, idx|
              loads_step = LoadArgumentStep.new(
                field_resolve_step: field_resolve_step,
                load_receiver: load_receiver,
                argument_value: inner_v,
                argument_definition: argument_definition,
                arguments: results,
                argument_key: idx,
              )
              ps.push(loads_step)
              @runner.add_step(loads_step)
            end
          else
            loads_step = LoadArgumentStep.new(
              field_resolve_step: field_resolve_step,
              load_receiver: load_receiver,
              argument_value: arg_value,
              argument_definition: argument_definition,
              arguments: argument_values,
              argument_key: argument_key,
            )
            ps.push(loads_step)
            @runner.add_step(loads_step)
          end
        else
        end
      end

      def value_from_ast(value_node, type)
        if type.non_null?
          type = type.of_type
        end

        if value_node.nil?
          nil
        elsif value_node.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          v = variable_values[value_node.name]
        elsif value_node.is_a?(GraphQL::Language::Nodes::NullValue)
          nil
        elsif type.list?
          inner_type = type.of_type
          if value_node.is_a?(Array)
            coerced_items = value_node.map do |inner_value_node|
              value_from_ast(inner_value_node, inner_type)
            end
            coerced_items.freeze
          else
            item_value = value_from_ast(value_node, inner_type)
            [item_value].freeze
          end

        elsif type.kind.input_object?
          coerced_obj = {}
          arg_nodes_by_name = value_node.arguments.each_with_object({}) do |arg_node, acc| # rubocop:disable Development/ContextIsPassedCop
            acc[arg_node.name] = arg_node
          end

          @query.types.arguments(type).each do |arg|
            arg_node = arg_nodes_by_name[arg.graphql_name]
            arg_key = arg.keyword
            if arg_node.nil?
              if arg.default_value?
                coerced_obj[arg_key] = arg.default_value
              end
              next
            end

            arg_value = value_from_ast(arg_node.value, arg.type)
            coerced_obj[arg_key] = arg_value # validate_value(arg, arg_value, state:)
          end

          # validate_value(type, coerced_obj.freeze, state:)
          coerced_obj
        elsif type.kind.leaf?
          if type.kind.enum?
            if value_node.is_a?(GraphQL::Language::Nodes::Enum)
              value_node = value_node.name
            end
          end

          begin
            type.coerce_input(value_node, @query.context)
          rescue GraphQL::UnauthorizedEnumValueError => enum_err
            begin
              @runner.schema.unauthorized_object(enum_err)
            rescue GraphQL::ExecutionError => ex_err
              ex_err
            end
          rescue GraphQL::ExecutionError => exec_err
            exec_err
          end
        else
          raise "Unexpected input type: #{type.to_type_signature}."
        end
      end
    end
  end
end
