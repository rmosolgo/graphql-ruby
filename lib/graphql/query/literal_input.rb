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
            from_arguments(ast_node.arguments, type.arguments, variables)
          end
        end
      end

      def self.defaults_for(argument_defns)
        if argument_defns.none? { |name, arg| arg.default_value? }
          GraphQL::Query::Arguments::NO_ARGS
        else
          from_arguments([], argument_defns, nil)
        end
      end

      def self.from_arguments(ast_arguments, argument_defns, variables)

        values_hash = {}
        indexed_arguments = ast_arguments.each_with_object({}) { |a, memo| memo[a.name] = a }

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
              value = arg_defn.prepare(value)

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
            values_hash[arg_name] = arg_defn.default_value
          end
        end

        GraphQL::Query::Arguments.new(values_hash, argument_definitions: argument_defns)
      end
    end
  end
end
