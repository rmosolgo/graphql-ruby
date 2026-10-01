# frozen_string_literal: true
module GraphQL
  module Execution
    class VariableValues
      class TooManyErrors < StandardError
      end

      # TODO merge this into VariableValues
      class ValidationState
        def initialize(max_errors:)
          @path = []
          @problems = []
          @max_errors = max_errors || Float::INFINITY
          @total_errors = 0
          clear
        end

        attr_reader :problems

        attr_reader :path
        attr_accessor :node, :type, :value

        def add_problem(msg)
          @problems ||= []
          if @total_errors >= @max_errors
            raise TooManyErrors
          else
            @total_errors += 1
            @problems << [msg, @path.dup]
          end
        end

        def clear
          @type = nil
          @node = nil
          @value = nil
          @path.clear
          @problems&.clear
        end

        def build_error
          if @problems.any?
            validation_result = Query::InputValidationResult.new
            @problems.each do |(message, path)|
              validation_result.add_problem(message, path)
            end
            if @total_errors >= @max_errors
              message = if @type.list?
                "Too many errors processing list variable, max validation error limit reached. Execution aborted"
              else
                "Too many errors processing variables, max validation error limit reached. Execution aborted"
              end
              too_many_result = GraphQL::Query::InputValidationResult.from_problem(message)
              validation_result.merge_result!(nil, too_many_result)
            end
            GraphQL::Query::VariableValidationError.new(@node, @type, @value, validation_result)
          else
            nil
          end
        end
      end

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
        validation_state = ValidationState.new(max_errors: max_errors)
        variable_nodes.each do |var_node|
          validation_state.clear
          var_name = var_node.name
          var_ast_value = get_indifferent(raw_values, var_name)
          var_type = type_from_ast(var_node.type)
          validation_state.node = var_node
          validation_state.value = var_ast_value
          validation_state.type = var_type

          if NONE.equal?(var_ast_value)
            validation_state.value = nil
            if !var_node.default_value.nil?
              @values[var_name] = @input_values.value_from_ast(var_node.default_value, var_type)
            elsif var_type.non_null?
              validation_state.add_problem(UNEXPECTED_NULL_MESSAGE)
            end
          elsif var_ast_value.nil? && var_type.non_null?
            validation_state.add_problem(UNEXPECTED_NULL_MESSAGE)
          else
            @values[var_node.name] = variable_value(var_node, var_type, var_ast_value, var_type, validation_state)
          end
        rescue TooManyErrors
          break
        ensure
          if (err = validation_state.build_error)
            @errors ||= []
            @errors << err
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

      def variable_value(var_node, var_type, value, type, validation_state)
        if type.non_null?
          if value == nil
            validation_state.add_problem(UNEXPECTED_NULL_MESSAGE)
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
            value.each_with_index.map do |v, idx|
              validation_state.path << idx
              variable_value(var_node, var_type, v, inner_type, validation_state)
            ensure
              validation_state.path.pop
            end.freeze
          else
            validation_state.path << 0
            result = [variable_value(var_node, var_type, value, inner_type, validation_state)].freeze
            validation_state.path.pop
            result
          end
        elsif type.kind.input_object?
          coerced_obj = {}

          if value.is_a?(Hash)

            value.each do |argument_name, value|
              if !(@query.types.argument(type, argument_name))
                validation_state.path << argument_name
                validation_state.add_problem("Field is not defined on #{type.graphql_name}")
                validation_state.path.pop
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
                arg_value = nil
              end

              if arg_value.nil? && arg.replace_null_with_default?
                arg_value = arg.default_value
              end
              validation_state.path << arg.graphql_name
              coerced_obj[arg_key] = variable_value(var_node, var_type, arg_value, arg.type, validation_state)
              validation_state.path.pop
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
                    validation_state.path << arg_name
                    variable_value(var_node, var_type, arg_value, arg.type, validation_state)
                    validation_state.path.pop
                  end
                elsif arg.default_value?
                  coerced_obj[arg_key] = arg.default_value
                end
              else
                validation_state.add_problem("Expected %{object} to be a key-value object." % { object: JSON.generate(value) })
              end
            end
          end

          coerced_obj
        elsif type.kind.leaf?
          coerced_value = type.coerce_input(value, @query.context)
          if coerced_value.nil?
            validation_state.add_problem("Could not coerce value #{GraphQL::Language.serialize(value)} to #{type.graphql_name}")
          end
          coerced_value
        else
          raise GraphQL::Error, "Unexpected input type: #{type.graphql_name}."
        end
      rescue GraphQL::CoercionError, GraphQL::ExecutionError => coercion_err
        validation_state.add_problem(coercion_err.message)
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
