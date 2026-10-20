# frozen_string_literal: true
# typed: true
module GraphQL
  module Execution
    # Coerces input values (variables and arguments) for a query.
    #
    # Static validation uses [value_from_ast](rdoc-ref:#value_from_ast) to check literal values,
    # and the runtime uses it to coerce them.
    class InputValues
      def initialize(query)
        @query = query
        @schema = query.schema
        @variable_values = nil
        @coerced_literals = nil
      end

      def variable_values
        @variable_values ||= GraphQL::Execution::VariableValues.new(
          @query,
          @query.selected_operation&.variables || EmptyObjects::EMPTY_ARRAY,
          @query.provided_variables,
        )
      end

      def argument_values(owner_defn, argument_nodes, field_resolve_step)
        arg_defns = @query.types.arguments(owner_defn)
        if arg_defns.empty?
          return [EmptyObjects::EMPTY_HASH, nil]
        end
        errors = nil #: untyped
        argument_values = {}

        arg_defns.each do |argument_definition|
          arg_ruby_key = argument_definition.keyword
          arg_graphql_key = argument_definition.graphql_name
          arg_node = argument_nodes.find { |a| a.name == arg_graphql_key }
          if arg_node.nil? || (arg_node.value.is_a?(Language::Nodes::VariableIdentifier) && !variable_values.key?(arg_node.value.name))
            if argument_definition.default_value?
              arg_value = value_from_ast(argument_definition.default_value, argument_definition.type)
              argument_value(argument_values, arg_ruby_key, argument_definition, arg_value, nil, field_resolve_step)
            elsif argument_definition.type.non_null?
              # Add an error
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

      # Raised by [value_from_ast](rdoc-ref:#value_from_ast) with `validate: true` when a literal value isn't valid for its type.
      class InvalidLiteralError < GraphQL::Error # :nodoc:
        # **Returns**
        #
        # - `String, nil` — A description of the problem, if there is one
        attr_reader :explanation

        def initialize(explanation = nil)
          @explanation = explanation
          super(explanation || "Invalid literal value")
        end
      end

      # Coerce `value_node` (a literal from a query string or a default value) for `type`.
      #
      # **Parameters**
      #
      # - `value_node` (`GraphQL::Language::Nodes::AbstractNode, Object`)
      # - `type` (`Class<GraphQL::Schema::Member>`)
      # - `validate` (`Boolean`) — When true, raise [InvalidLiteralError](rdoc-ref:InvalidLiteralError) for invalid values and treat variable references as valid.
      def value_from_ast(value_node, type, validate: false)
        if type.non_null?
          type = type.of_type
          if validate && (value_node.nil? || value_node.is_a?(Language::Nodes::NullValue))
            raise InvalidLiteralError
          end
        end

        if value_node.nil? || (value_node.is_a?(Language::Nodes::NullValue) && (validate || !type.kind.leaf?))
          nil
        elsif value_node.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          # Variables are checked by `VariableUsagesAreAllowed` during validation
          validate ? nil : variable_values.coerced_value(value_node.name)
        elsif type.list?
          inner_type = type.of_type
          if value_node.is_a?(Array)
            coerced_items = value_node.map do |inner_value_node|
              value_from_ast(inner_value_node, inner_type, validate: validate)
            end
            coerced_items.freeze
          else
            item_value = value_from_ast(value_node, inner_type, validate: validate)
            [item_value].freeze
          end
        elsif type.kind.input_object?
          coerced_obj = {}
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

              coerced_obj[arg_key] = value_from_ast(arg_value, arg.type, validate: validate)
            end
          elsif value_node.is_a?(Language::Nodes::InputObject)
            if validate && type.one_of? && value_node.arguments.size != 1 # rubocop:disable Development/ContextIsPassedCop
              raise InvalidLiteralError, "`#{type.graphql_name}` is a OneOf type, so only one argument may be given (instead of #{value_node.arguments.size})" # rubocop:disable Development/ContextIsPassedCop
            end
            arg_nodes_by_name = value_node.arguments.each_with_object({}) do |arg_node, acc| # rubocop:disable Development/ContextIsPassedCop
              acc[arg_node.name] = arg_node
            end

            @query.types.arguments(type).each do |arg|
              arg_node = arg_nodes_by_name[arg.graphql_name]
              arg_key = arg.keyword
              if arg_node.nil? || (!validate && arg_node.value.is_a?(Language::Nodes::VariableIdentifier) && !variable_values.key?(arg_node.value.name))
                if arg.default_value?
                  coerced_obj[arg_key] = arg.default_value
                elsif validate && arg.type.non_null?
                  raise InvalidLiteralError
                end
                next
              end

              coerced_obj[arg_key] = value_from_ast(arg_node.value, arg.type, validate: validate)
            end

            if validate
              value_node.arguments.each do |arg_node| # rubocop:disable Development/ContextIsPassedCop
                if @query.types.argument(type, arg_node.name).nil?
                  raise InvalidLiteralError
                end
              end
            end
          elsif validate
            raise InvalidLiteralError
          end

          coerced_obj
        elsif type.kind.enum?
          if validate
            enum_value_from_ast(value_node, type)
          else
            if value_node.is_a?(Language::Nodes::Enum)
              value_node = value_node.name
            end
            coerce_leaf_value(value_node, type)
          end
        elsif type.kind.scalar?
          if validate
            scalar_value_from_ast(value_node, type)
          elsif (literals = @coerced_literals&.[](type)) && literals.key?(value_node)
            # This literal was already coerced during validation
            literals[value_node]
          else
            if value_node.is_a?(Language::Nodes::AbstractNode) || value_node.is_a?(Array)
              value_node = coerce_untyped_input(value_node)
            end
            coerce_leaf_value(value_node, type)
          end
        elsif validate
          raise InvalidLiteralError
        else
          raise "Unexpected input type: #{type.to_type_signature}."
        end
      end

      private

      def coerce_leaf_value(value, type)
        type.coerce_input(value, @query.context)
      rescue GraphQL::UnauthorizedEnumValueError => enum_err
        @schema.unauthorized_object(enum_err)
      end

      def enum_value_from_ast(value_node, type)
        if !value_node.is_a?(Language::Nodes::Enum)
          raise InvalidLiteralError
        end
        allowed_values = @query.types.enum_values(type)
        if allowed_values.none? { |v| v.graphql_name == value_node.name }
          raise InvalidLiteralError, "Expected #{GraphQL::Language.serialize(value_node.name)} to be one of: #{allowed_values.map(&:graphql_name).join(', ')}"
        end
        # Authorization is checked at runtime
        nil
      end

      def scalar_value_from_ast(value_node, type)
        literals = (@coerced_literals ||= {}.compare_by_identity)[type] ||= {}.compare_by_identity
        if literals.key?(value_node)
          return literals[value_node]
        end

        if contains_variable?(value_node)
          # Variables aren't supported inside scalar literals
          raise InvalidLiteralError
        end

        ruby_value = case value_node
        when Language::Nodes::InputObject, Array
          # Top-level enums are passed as AST nodes,
          # but nested ones are converted to strings, to match previous behavior.
          coerce_untyped_input(value_node)
        else
          value_node
        end
        coerced_value = begin
          type.coerce_input(ruby_value, @query.context)
        rescue GraphQL::CoercionError
          raise
        rescue StandardError => err
          @query.handle_or_reraise(err)
        end
        if coerced_value.nil?
          raise InvalidLiteralError, "Could not coerce value #{GraphQL::Language.serialize(ruby_value)} to #{type.graphql_name}"
        end
        literals[value_node] = coerced_value
      end

      def contains_variable?(value_node)
        case value_node
        when Language::Nodes::VariableIdentifier
          true
        when Array
          value_node.any? { |v| contains_variable?(v) }
        when Language::Nodes::InputObject
          value_node.arguments.any? { |arg| contains_variable?(arg.value) } # rubocop:disable Development/ContextIsPassedCop
        else
          false
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
            coerce_untyped_input(variable_values[input_value.name])
          else
            raise "Unhandled untyped input AST node: #{input_value.class}"
          end
        when Array
          input_value.map { |v| coerce_untyped_input(v) }
        else
          input_value
        end
      end
    end
  end
end
