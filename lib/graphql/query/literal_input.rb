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
          case type.kind.name
          when "SCALAR"
            # TODO smell
            # This gets used for plain values during subscriber.trigger
            if variables
              type.coerce_input(ast_node, variables.context)
            else
              type.coerce_isolated_input(ast_node)
            end
          when "ENUM"
            # TODO smell
            # This gets used for plain values sometimes
            v = ast_node.is_a?(GraphQL::Language::Nodes::Enum) ? ast_node.name : ast_node
            if variables
              type.coerce_input(v, variables.context)
            else
              type.coerce_isolated_input(v)
            end
          when "NON_NULL"
            LiteralInput.coerce(type.of_type, ast_node, variables)
          when "LIST"
            if ast_node.is_a?(Array)
              ast_node.map { |element_ast| LiteralInput.coerce(type.of_type, element_ast, variables) }
            else
              [LiteralInput.coerce(type.of_type, ast_node, variables)]
            end
          when "INPUT_OBJECT"
            # TODO smell: handling AST vs handling plain Ruby
            next_args = ast_node.is_a?(Hash) ? ast_node : ast_node.arguments
            from_arguments(next_args, type, variables)
          else
            raise "Invariant: unexpected type to coerce to: #{type}"
          end
        end
      end

      def self.from_arguments(ast_arguments, argument_owner, variables)
        context = variables ? variables.context : nil
        values_hash = {}
        defaults_used = Set.new

        indexed_arguments = case ast_arguments
        when Hash
          ast_arguments
        when Array
          ast_arguments.each_with_object({}) { |a, memo| memo[a.name] = a }
        else
          raise ArgumentError, "Unexpected ast_arguments: #{ast_arguments}"
        end

        argument_defns = argument_owner.arguments
        argument_defns.each do |arg_name, arg_defn|
          ast_arg = indexed_arguments[arg_name]
          # First, check the argument in the AST.
          # If the value is a variable,
          # only add a value if the variable is actually present.
          # Otherwise, coerce the value in the AST, prepare the value and add it.
          #
          # TODO: since indexed_arguments can come from a plain Ruby hash,
          # have to check for `false` or `nil` as hash values. This is getting smelly :S
          if indexed_arguments.key?(arg_name)
            arg_value = ast_arg.is_a?(GraphQL::Language::Nodes::Argument) ? ast_arg.value : ast_arg

            value_is_a_variable = arg_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)

            if (!value_is_a_variable || (value_is_a_variable && variables.key?(arg_value.name)))

              value = coerce(arg_defn.type, arg_value, variables)
              # Legacy `prepare` application
              if arg_defn.is_a?(GraphQL::Argument)
                value = arg_defn.prepare(value, context)
              end

              if value.is_a?(GraphQL::ExecutionError)
                value.ast_node = ast_arg
                raise value
              end

              values_hash[arg_name] = value
            end
          end

          # Then, the definition for a default value.
          # If the definition has a default value and
          # a value wasn't provided from the AST,
          # then add the default value.
          if arg_defn.default_value? && !values_hash.key?(arg_name)
            value = arg_defn.default_value
            defaults_used << arg_name
            # `context` isn't present when pre-calculating defaults
            if context
              if arg_defn.is_a?(GraphQL::Argument)
                value = arg_defn.prepare(value, context)
              end
              if value.is_a?(GraphQL::ExecutionError)
                value.ast_node = ast_arg
                raise value
              end
            end
            values_hash[arg_name] = value
          end
        end

        if argument_owner.is_a?(Class) || argument_owner.is_a?(GraphQL::Schema::Field)
          # A Schema::InputObject, Schema::GraphQL::Field, Schema::Directive, logic from Query::Arguments#to_kwargs
          ruby_kwargs = {}
          values_hash.each do |key, value|
            ruby_kwargs[Schema::Member::BuildType.underscore(key).to_sym] = value
          end
          if argument_owner.is_a?(Class) && argument_owner < GraphQL::Schema::InputObject
            argument_owner.new(ruby_kwargs: ruby_kwargs, context: context, defaults_used: defaults_used)
          else
            ruby_kwargs
          end
        else
          result = argument_owner.arguments_class.new(values_hash, context: context, defaults_used: defaults_used)
          result.prepare
        end
      end
    end
  end
end
