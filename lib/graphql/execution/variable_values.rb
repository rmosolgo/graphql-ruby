# frozen_string_literal: true
module GraphQL
  module Execution
    class VariableValues
      def initialize(query: nil, values: nil, errors: nil, input_values: nil)
        @values = values
        @errors = errors
        @query = query
        @input_values = input_values
        if @values.nil?
          build_variable_values
        end
        @errors ||= EmptyObjects::EMPTY_ARRAY
      end

      attr_reader :errors

      def [](key)
        @values[key]
      end

      def fetch(key, &block)
        @values.fetch(key, &block)
      end

      def each(&block)
        @values.each(&block)
      end

      def length
        @values.length
      end

      def to_h
        @values.to_h
      end

      def key?(k)
        @values.key?(k)
      end

      NO_VARIABLES = VariableValues.new(values: EmptyObjects::EMPTY_HASH)

      private

      def build_variable_values
        variable_nodes = @query.selected_operation.variables
        raw_values = deep_stringify(@query.provided_variables)
        @values = {}
        max_errors = @query.schema.validate_max_errors
        variable_nodes.each do |var_node|
          if @errors && max_errors && @errors.length >= max_errors
            add_max_errors_reached_message
            break
          end
          var_name = var_node.name
          var_ast_value = get_indifferent(raw_values, var_name)
          var_type = type_from_ast(var_node.type)

          if NONE.equal?(var_ast_value)
            if !var_node.default_value.nil?
              @values[var_name] = @input_values.value_from_ast(var_node.default_value, var_type)
            elsif var_type.non_null?
              add_error_from_message(var_node, var_type, nil, UNEXPECTED_NULL_MESSAGE)
            end
          elsif var_ast_value.nil? && var_type.non_null?
            add_error_from_message(var_node, var_type, nil, UNEXPECTED_NULL_MESSAGE)
          else
            @values[var_node.name] = variable_value(var_node, var_type, var_ast_value, var_type)
          end
        end
        if @errors
          @values.clear
        end
      end

      UNEXPECTED_NULL_MESSAGE = "Expected value to not be null"

      def type_from_ast(ast_node)
        case ast_node
        when Language::Nodes::NonNullType
          type_from_ast(ast_node.of_type).to_non_null_type
        when Language::Nodes::ListType
          type_from_ast(ast_node.of_type).to_list_type
        else
          @query.types.type(ast_node.name)
        end
      end

      def add_error_from_message(var_node, var_type, value, msg, path = nil)
        @errors ||= []
        validation_result = GraphQL::Query::InputValidationResult.from_problem(msg, path)
        @errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, value, validation_result)
      end

      def variable_value(var_node, var_type, value, type)
        if type.non_null?
          if value == nil
            add_error_from_message(var_node, var_type, nil, UNEXPECTED_NULL_MESSAGE)
            return
          end
          type = type.of_type
        end

        if value.is_a?(Language::Nodes::Enum)
          value = value.name
        end

        if value.nil?
          nil
        elsif type.list?
          inner_type = type.of_type
          if value.is_a?(Array)
            value.map { |v| variable_value(var_node, var_type, v, inner_type) }.freeze
          else
            [variable_value(var_node, var_type, value, inner_type)].freeze
          end
        elsif type.kind.input_object?
          coerced_obj = {}

          if value.is_a?(Hash)

            value.each do |argument_name, value|
              if !(@query.types.argument(type, argument_name))
                add_error_from_message(var_node, var_type, value, "Field is not defined on #{type.graphql_name}", [argument_name])
              end
            end

            @query.types.arguments(type).each do |arg|
              arg_key = arg.keyword
              if value.key?(arg.graphql_name)
                arg_value = value[arg.graphql_name]
              elsif value.key?(sym_name = arg.graphql_name.to_sym)
                arg_value = value[sym_name]
              elsif arg.default_value?
                coerced_obj[arg_key] = arg.default_value
                next
              else
                next
              end

              if arg_value.nil? && arg.replace_null_with_default?
                arg_value = arg.default_value
              end

              coerced_obj[arg_key] = variable_value(var_node, var_type, arg_value, arg.type)
            end
          else
            @query.types.arguments(type).each do |arg|
              arg_key = arg.keyword
              arg_name = arg.graphql_name
              if value.is_a?(Language::Nodes::InputObject)
                if (v_node = value.arguments.find { |a| a.name == arg_name }) # rubocop:disable Development/ContextIsPassedCop
                  arg_value = v_node.value
                  coerced_obj[arg_key] = if arg_value.nil? && arg.replace_null_with_default?
                    arg.default_value
                  else
                    variable_value(var_node, var_type, arg_value, arg.type)
                  end
                elsif arg.default_value?
                  coerced_obj[arg_key] = arg.default_value
                end
              else
                add_error_from_message(var_node, var_type, value, "Expected %{object} to be a key-value object." % { object: JSON.generate(value) })
              end
            end
          end

          coerced_obj
        elsif type.kind.leaf?
          coerced_value = type.coerce_input(value, @query.context)
          if coerced_value.nil?
            add_error_from_message(var_node, var_type, value, "Could not coerce value #{GraphQL::Language.serialize(value)} to #{type.graphql_name}")
          end
          coerced_value
        else
          raise GraphQL::Error, "Unexpected input type: #{type.graphql_name}."
        end
      rescue GraphQL::CoercionError, GraphQL::ExecutionError => coercion_err
        @errors ||= []
        validation_result = Query::InputValidationResult.from_problem(coercion_err.message, message: coercion_err.message, extensions: coercion_err.extensions)
        @errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, value, validation_result)
      end

      def add_max_errors_reached_message
        message = "Too many errors processing variables, max validation error limit reached. Execution aborted"
        validation_result = GraphQL::Query::InputValidationResult.from_problem(message)
        @errors << GraphQL::Query::VariableValidationError.new(nil, nil, nil, validation_result, msg: message)
      end

      NONE = Object.new


      def deep_stringify(val)
        case val
        when Array
          val.map { |v| deep_stringify(v) }
        when Hash
          new_val = {}
          val.each do |k, v|
            new_val[k.to_s] = deep_stringify(v)
          end
          new_val
        else
          val
        end
      end

      def get_indifferent(hash, key_s)
        if hash.key?(key_s)
          hash[key_s]
        elsif hash.key?(sym_name = key_s.to_sym)
          hash[sym_name]
        else
          NONE
        end
      end
    end
  end
end
