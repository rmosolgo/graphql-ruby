# frozen_string_literal: true
module GraphQL
  class Query
    # Turn query string values into something useful for query execution
    class LiteralInput
      def self.coerce(type, ast_node, variables)
        case ast_node
        when nil
          nil
        when Language::Nodes::NullValue
          nil
        when Language::Nodes::VariableIdentifier
          variables[ast_node.name]
        else
          case type
          when GraphQL::ScalarType
            type.coerce_input(ast_node, variables.context)
          when GraphQL::EnumType
            type.coerce_input(ast_node.name, variables.context)
          when GraphQL::NonNullType
            LiteralInput.coerce(type.of_type, ast_node, variables)
          when GraphQL::ListType
            if ast_node.is_a?(Array)
              ast_node.map { |element_ast| LiteralInput.coerce(type.of_type, element_ast, variables) }
            else
              [LiteralInput.coerce(type.of_type, ast_node, variables)]
            end
          when GraphQL::InputObjectType
            from_arguments(ast_node, type.arguments, variables)
          end
        end
      end

      def self.defaults_for(argument_defns)
        if argument_defns.values.none?(&:default_value?)
          GraphQL::Query::Arguments::NO_ARGS
        else
          from_arguments([], argument_defns, nil)
        end
      end

      def self.from_arguments(ast_node, argument_defns, variables)
        # Variables is nil when making .defaults_for
        context = variables ? variables.context : nil
        values_hash = {}
        indexed_arguments = ast_node.arguments.each_with_object({}) { |a, memo| memo[a.name] = a }

        argument_defns.each do |arg_name, arg_defn|
          ast_arg = indexed_arguments[arg_name]
          # First, check the argument in the AST.
          # If the value is a variable,
          # only add a value if the variable is actually present.
          # Otherwise, coerce the value in the AST, prepare the value and add it.
          if ast_arg
            value_is_a_variable = ast_arg.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)

            if (!value_is_a_variable || (value_is_a_variable && variables.key?(ast_arg.value.name)))

              value = coerce(arg_defn.type, ast_arg.value, variables)
              value = arg_defn.prepare(value, context)

              if value.is_a?(GraphQL::ExecutionError)
                value.ast_node = ast_arg
                raise value
              end

              values_hash[ast_arg.name] = value
            end
          end

          # Then, the definition for a default value.
          # If the definition has a default value and
          # a value wasn't provided from the AST,
          # then add the default value.
          if arg_defn.default_value? && !values_hash.key?(arg_name)
            value = arg_defn.default_value
            # `context` isn't present when pre-calculating defaults
            if context
              value = arg_defn.prepare(value, context)
              if value.is_a?(GraphQL::ExecutionError)
                value.ast_node = ast_arg
                raise value
              end
            end
            values_hash[arg_name] = value
          end
        end

        ast_node.arguments_class ||= GraphQL::Query::Arguments
            .construct_arguments_class(argument_definitions: argument_defns)

        ast_node.arguments_class.instantiate_arguments(values_hash)
      end
    end
  end
end
