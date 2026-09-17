# frozen_string_literal: true
module GraphQL
  module Execution
    class InputValues

      class VariableValues
        def initialize(values:, errors:)
          @values = values
          @errors = errors || EmptyObjects::EMPTY_ARRAY
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
      end

      NO_VARIABLES = VariableValues.new(values: EmptyObjects::EMPTY_HASH, errors: EmptyObjects::EMPTY_ARRAY)
      NONE = Object.new

      def initialize(query)
        @query = query
        @schema = query.schema
        @variable_values = nil
        @variable_errors = nil
      end

      attr_reader :variable_errors

      def variable_values
        @variable_values ||= begin
          variable_nodes = @query.selected_operation.variables
          if variable_nodes.empty?
            NO_VARIABLES
          else
            raw_values = @query.provided_variables
            values = {}
            max_errors = @query.schema.validate_max_errors
            variable_nodes.each do |var_node|
              if @variable_errors && max_errors && @variable_errors.length >= max_errors
                add_max_errors_reached_message
                break
              end
              var_name = var_node.name
              var_ast_value = get_indifferent(raw_values, var_name)
              var_type = type_from_ast(var_node.type)

              if NONE.equal?(var_ast_value)
                if !var_node.default_value.nil?
                  values[var_name] = value_from_ast(var_node.default_value, var_type)
                elsif var_type.non_null?
                  @variable_errors ||= []
                  validation_result = GraphQL::Query::InputValidationResult.from_problem("Expected value to not be null")
                  @variable_errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, nil, validation_result)
                end
              elsif var_ast_value.nil? && var_type.non_null?
                # TODO dry with above
                @variable_errors ||= []
                validation_result = GraphQL::Query::InputValidationResult.from_problem("Expected value to not be null")
                @variable_errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, nil, validation_result)
              else
                values[var_node.name] = variable_value(var_node, var_type, var_ast_value, var_type)
              end
            end
            if @variable_errors
              values.clear
            end
            VariableValues.new(values: values, errors: @variable_errors)
          end
        end
      end

      def argument_values(owner_defn, argument_nodes, field_resolve_step)
        arg_defns = @query.types.arguments(owner_defn)
        argument_values = {}
        errors = nil

        arg_defns.each do |argument_definition|
          arg_ruby_key = argument_definition.keyword
          arg_graphql_key = argument_definition.graphql_name
          arg_node = argument_nodes.find { |a| a.name == arg_graphql_key }
          if arg_node.nil? || (arg_node.value.is_a?(Language::Nodes::VariableIdentifier) && !variable_values.key?(arg_node.value.name))
            if argument_definition.default_value?
              arg_value = value_from_ast(argument_definition.default_value, argument_definition.type)
              argument_value(argument_values, arg_ruby_key, argument_definition, arg_value, nil, field_resolve_step)
            end
          else
            arg_value = value_from_ast(arg_node.value, argument_definition.type)
            argument_value(argument_values, arg_ruby_key, argument_definition, arg_value, nil, field_resolve_step)
          end
        rescue GraphQL::RuntimeError => exec_err
          errors ||= []
          errors << exec_err
        end

        return argument_values, errors
      end

      private

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

      def variable_value(var_node, var_type, value, type)
        if type.non_null?
          if value == nil
            # TODO dry with above
            @variable_errors ||= []
            validation_result = GraphQL::Query::InputValidationResult.from_problem("Expected value to not be null")
            @variable_errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, nil, validation_result)
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
                @variable_errors ||= []
                validation_result = Query::InputValidationResult.from_problem("Field is not defined on #{type.graphql_name}", [argument_name])
                @variable_errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, value, validation_result)
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
                @variable_errors ||= []
                validation_result = GraphQL::Query::InputValidationResult.from_problem("Expected %{object} to be a key-value object." % { object: JSON.generate(value) })
                @variable_errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, value, validation_result)
              end
            end
          end

          coerced_obj
        elsif type.kind.leaf?
          coerced_value = type.coerce_input(value, @query.context)
          if coerced_value.nil?
            @variable_errors ||= []
            validation_result = Query::InputValidationResult.from_problem("Could not coerce value #{GraphQL::Language.serialize(value)} to #{type.graphql_name}")
            @variable_errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, value, validation_result)
          end
          coerced_value
        else
          raise GraphQL::Error, "Unexpected input type: #{type.graphql_name}."
        end
      rescue GraphQL::CoercionError => coercion_err
        @variable_errors ||= []
        validation_result = Query::InputValidationResult.from_problem(coercion_err.message, message: coercion_err.message, extensions: coercion_err.extensions)
        @variable_errors << GraphQL::Query::VariableValidationError.new(var_node, var_type, value, validation_result)
      end

      def argument_value(argument_values, argument_key, argument_definition, arg_value, override_type, field_resolve_step)
        treat_as_type = override_type || argument_definition.type
        if treat_as_type.non_null?
          if arg_value.nil?
            treat_as_type.coerce_input(arg_value, @query.context)
          end
          treat_as_type = treat_as_type.of_type
        end

        if arg_value.nil? && argument_definition.replace_null_with_default?
          arg_value = argument_definition.default_value
        end

        if treat_as_type.kind.list? && !arg_value.nil?
          inner_t = treat_as_type.of_type
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

        if arg_value && treat_as_type.kind.input_object?
          arg_defns = @query.types.arguments(treat_as_type)
          new_arg_value = {}
          arg_defns.each do |inner_arg_defn|
            inner_arg_key = inner_arg_defn.keyword
            if arg_value.is_a?(Hash)
              if arg_value.key?(inner_arg_key)
                inner_arg_value = arg_value[inner_arg_key]
                argument_value(new_arg_value, inner_arg_key, inner_arg_defn, inner_arg_value, nil, field_resolve_step)
              end
            else
              inner_arg_name = inner_arg_defn.graphql_name
              inner_arg_value = arg_value.arguments.find { |a| a.name == inner_arg_name } # rubocop:disable Development/ContextIsPassedCop
              if inner_arg_value
                argument_value(new_arg_value, inner_arg_key, inner_arg_defn, inner_arg_value, nil, field_resolve_step)
              end
            end
          end
          arg_value = treat_as_type.new(nil, ruby_kwargs: new_arg_value, context: @query.context, defaults_used: nil)
        end

        if override_type.nil? # only on root arguments, not list elements
          arg_value = begin
            argument_definition.prepare_value(nil, arg_value, context: @query.context)
          rescue StandardError => err
            @schema.handle_or_reraise(@query.context, err, object: nil, arguments: argument_values, field: field_resolve_step&.field_definition)
          end
        end

        if field_resolve_step && arg_value && override_type.nil? && argument_definition.loads
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
              field_resolve_step.runner.add_step(loads_step)
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
            field_resolve_step.runner.add_step(loads_step)
          end
        else
          argument_values[argument_key] = arg_value
        end
        nil
      end

      public

      class AstCoercionFailed < GraphQL::Error
      end

      def value_from_ast(value_node, type)
        if type.non_null?
          inner_type = type.of_type
          value = value_from_ast(value_node, inner_type)
          if value.nil?
            raise AstCoercionFailed
          else
            value
          end
        elsif value_node.nil?
          nil
        elsif value_node.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          variable_values[value_node.name]
        elsif type.list?
          inner_type = type.of_type
          if value_node.is_a?(Array)
            coerced_items = value_node.map do |inner_value_node|
              value_from_ast(inner_value_node, inner_type)
            end
            coerced_items.freeze
          elsif value_node.is_a?(Language::Nodes::NullValue)
            nil
          else
            item_value = value_from_ast(value_node, inner_type)
            [item_value].freeze
          end
        elsif type.kind.input_object?
          coerced_obj = {}
          # TODO manually handle NullValue here?
          if value_node.is_a?(Hash)
            @query.types.arguments(type).each do |arg|
              arg_value = value_node[arg.keyword]
              arg_key = arg.keyword
              if arg_value.nil?
                if arg.default_value?
                  coerced_obj[arg_key] = arg.default_value
                end
                next
              end

              coerced_obj[arg_key] = value_from_ast(arg_value, arg.type)
            end
          else
            arg_nodes_by_name = value_node.arguments.each_with_object({}) do |arg_node, acc| # rubocop:disable Development/ContextIsPassedCop
              acc[arg_node.name] = arg_node
            end

            @query.types.arguments(type).each do |arg|
              arg_node = arg_nodes_by_name[arg.graphql_name]
              arg_key = arg.keyword
              if arg_node.nil? || (arg_node.value.is_a?(Language::Nodes::VariableIdentifier) && !variable_values.key?(arg_node.value.name))
                if arg.default_value?
                  coerced_obj[arg_key] = arg.default_value
                end
                next
              end

              arg_value = value_from_ast(arg_node.value, arg.type)
              coerced_obj[arg_key] = arg_value
            end
          end


          coerced_obj
        elsif type.kind.leaf?
          if value_node.is_a?(Language::Nodes::AbstractNode) || value_node.is_a?(Array)
            value_node = coerce_untyped_input(value_node)
          end

          begin
            type.coerce_input(value_node, @query.context)
          rescue GraphQL::UnauthorizedEnumValueError => enum_err
            @schema.unauthorized_object(enum_err)
          end
        else
          raise "Unexpected input type: #{type.to_type_signature}."
        end
      end

      private

      def get_indifferent(hash, key_s)
        if hash.key?(key_s)
          hash[key_s]
        elsif hash.key?(sym_name = key_s.to_sym)
          hash[sym_name]
        else
          NONE
        end
      end

      def coerce_untyped_input(input_value)
        case input_value
        when Language::Nodes::AbstractNode
          case input_value
          when Language::Nodes::NullValue
            nil
          when Language::Nodes::Enum
            input_value.name
          when Language::Nodes::InputObject
            value_h = {}
            input_value.arguments.each do |arg| # rubocop:disable Development/ContextIsPassedCop
              value_h[arg.name] = coerce_untyped_input(arg.value)
            end
            value_h
          when Language::Nodes::VariableIdentifier
            coerce_untyped_input(@query.variables[input_value.name])
          else
            raise "Unhandled untyped input AST node: #{input_value.class}"
          end
        when Array
          input_value.map { |v| coerce_untyped_input(v) }
        else
          input_value
        end
      end

      def add_max_errors_reached_message
        message = "Too many errors processing variables, max validation error limit reached. Execution aborted"
        validation_result = GraphQL::Query::InputValidationResult.from_problem(message)
        @variable_errors << GraphQL::Query::VariableValidationError.new(nil, nil, nil, validation_result, msg: message)
      end
    end
  end
end
