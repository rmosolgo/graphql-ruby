# frozen_string_literal: true
# typed: false
module GraphQL
  module Execution
    # Validates and coerces a query's provided variables in a single pass.
    #
    # Reading methods (`#[]`, `#fetch`, `#to_h`, ...) return the values _as provided_ by the client
    # (or the default value from the query string), so that existing callers keep working.
    # Coerced values are available from [coerced_value](rdoc-ref:#coerced_value) for the runtime.
    class VariableValues
      extend Forwardable

      # **Returns**
      #
      # - `Array<GraphQL::Query::VariableValidationError>` — Any errors encountered when coercing the provided variables
      attr_reader :errors

      attr_reader :context

      def initialize(query, ast_variables, provided_variables)
        @query = query
        @context = query.context
        @types = query.types
        @schema = query.schema
        @provided_variables = deep_stringify(provided_variables)
        @errors = []
        @storage = {}
        @coerced_values = {}
        build_values(ast_variables)
      end

      def_delegators :@storage, :length, :key?, :[], :fetch, :to_h, :each

      # **Returns**
      #
      # - `Object` — The coerced value for the variable named `name`, or `nil` if it wasn't given
      def coerced_value(name) # :nodoc:
        @coerced_values[name]
      end

      private

      UNEXPECTED_NULL_MESSAGE = "Expected value to not be null"
      INVALID_OBJECT_MESSAGE = "Expected %{object} to be a key-value object."

      def build_values(ast_variables)
        max_errors = @schema.validate_max_errors
        ast_variables.each do |ast_variable|
          if max_errors && max_errors <= @errors.size
            add_max_errors_reached_message
            break
          end
          variable_type = GraphQL::Schema::TypeExpression.build_type(@types, ast_variable.type)
          if variable_type.nil? || !variable_type.unwrap.kind.input?
            # Pass -- it will get handled by a validator
            next
          end

          variable_name = ast_variable.name
          default_value = ast_variable.default_value
          value_was_provided = @provided_variables.key?(variable_name)

          if value_was_provided || default_value.nil?
            provided_value = @provided_variables[variable_name]
            validation_result = GraphQL::Query::InputValidationResult.new
            remaining_errors = max_errors ? max_errors - @errors.size : nil
            path = []
            coerced_value = begin
              coerce_variable_value(provided_value, variable_type, path, validation_result, remaining_errors)
            rescue GraphQL::ExecutionError => ex
              # TODO: This should really include the path to the problematic node in the variable value
              validation_result = GraphQL::Query::InputValidationResult.from_problem(ex.message)
              nil
            end
            if !validation_result.valid?
              @errors << GraphQL::Query::VariableValidationError.new(ast_variable, variable_type, provided_value, validation_result)
            elsif value_was_provided
              @storage[variable_name] = provided_value
              @coerced_values[variable_name] = coerced_value
            end
          elsif default_value.is_a?(Language::Nodes::NullValue)
            @storage[variable_name] = nil
            @coerced_values[variable_name] = nil
          else
            @storage[variable_name] = default_value
            @coerced_values[variable_name] = @query.input_values.value_from_ast(default_value, variable_type)
          end
        end
      end

      def coerce_variable_value(value, type, path, result, max_errors)
        if type.non_null?
          if value.nil?
            result.add_problem(UNEXPECTED_NULL_MESSAGE, path.dup)
            return nil
          end
          type = type.of_type
        end

        if value.nil?
          nil
        elsif type.list?
          coerce_list_value(value, type.of_type, path, result, max_errors)
        elsif type.kind.input_object?
          coerce_input_object_value(value, type, path, result)
        elsif type.kind.enum?
          coerce_enum_value(value, type, path, result)
        elsif type.kind.scalar?
          coerce_scalar_value(value, type, path, result)
        else
          raise GraphQL::Error, "Unexpected input type: #{type.graphql_name}."
        end
      end

      def coerce_list_value(value, item_type, path, result, max_errors)
        items = value.is_a?(Array) ? value : [value]
        coerced_items = Array.new(items.size)
        invalid_items = 0
        items.each_with_index do |item, idx|
          item_result = GraphQL::Query::InputValidationResult.new
          path.push(idx)
          coerced_items[idx] = coerce_variable_value(item, item_type, path, item_result, nil)
          path.pop
          if !item_result.valid?
            if max_errors
              if invalid_items == max_errors
                result.add_problem("Too many errors processing list variable, max validation error limit reached. Execution aborted", [*path, nil])
                break
              end
              invalid_items += 1
            end
            item_result.problems.each do |problem|
              result.add_problem(problem["explanation"], problem["path"], message: problem["message"], extensions: problem["extensions"])
            end
          end
        end
        coerced_items.freeze
      end

      def coerce_input_object_value(value, type, path, result)
        if value.is_a?(Array) || !(value.respond_to?(:to_h) || value.respond_to?(:to_unsafe_h))
          result.add_problem(INVALID_OBJECT_MESSAGE % { object: JSON.generate(value) }, path.dup)
          return nil
        end

        coerced_obj = {}
        value.each do |argument_name, argument_value|
          path.push(argument_name)
          argument = @types.argument(type, argument_name)
          if argument.nil?
            result.add_problem("Field is not defined on #{type.graphql_name}", path.dup)
          else
            if argument_value.nil? && argument.replace_null_with_default?
              coerced_obj[argument.keyword] = argument.default_value
            else
              coerced_obj[argument.keyword] = coerce_variable_value(argument_value, argument.type, path, result, nil)
            end
          end
          path.pop
        end

        @types.arguments(type).each do |argument|
          if !value.key?(argument.graphql_name)
            if argument.default_value?
              coerced_obj[argument.keyword] = argument.default_value
            elsif argument.type.non_null?
              path.push(argument.graphql_name)
              result.add_problem(UNEXPECTED_NULL_MESSAGE, path.dup)
              path.pop
            end
          end
        end

        if type.one_of?
          if value.size == 1
            value.each do |name, v|
              if v.nil?
                result.add_problem("'#{type.graphql_name}' requires exactly one argument, but '#{name}' was `null`.", path.dup)
              end
            end
          else
            result.add_problem("'#{type.graphql_name}' requires exactly one argument, but #{value.size} were provided.", path.dup)
          end
        end

        coerced_obj
      end

      def coerce_enum_value(value, type, path, result)
        allowed_values = @types.enum_values(type)
        matching_value = allowed_values.find { |v| v.graphql_name == value }
        if matching_value.nil?
          result.add_problem("Expected #{GraphQL::Language.serialize(value)} to be one of: #{allowed_values.map(&:graphql_name).join(', ')}", path.dup)
          nil
        else
          begin
            type.coerce_input(value, @context)
          rescue GraphQL::UnauthorizedEnumValueError => enum_err
            @schema.unauthorized_object(enum_err)
          end
        end
      rescue GraphQL::ExecutionError => err
        result.add_problem(err.message, path.dup)
        nil
      end

      def coerce_scalar_value(value, type, path, result)
        coerced_value = begin
          type.coerce_input(value, @context)
        rescue GraphQL::CoercionError => err
          result.add_problem(err.message, path.dup, message: err.message, extensions: err.extensions)
          return nil
        rescue GraphQL::ExecutionError => err
          result.add_problem(err.message, path.dup)
          return nil
        rescue StandardError => err
          @query.handle_or_reraise(err)
        end

        if coerced_value.nil?
          result.add_problem("Could not coerce value #{GraphQL::Language.serialize(value)} to #{type.graphql_name}", path.dup)
        end
        coerced_value
      end

      def add_max_errors_reached_message
        message = "Too many errors processing variables, max validation error limit reached. Execution aborted"
        validation_result = GraphQL::Query::InputValidationResult.from_problem(message)
        @errors << GraphQL::Query::VariableValidationError.new(nil, nil, nil, validation_result, msg: message)
      end

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
    end
  end
end
