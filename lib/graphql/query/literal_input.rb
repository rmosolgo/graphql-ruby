module GraphQL
  class Query
    # Turn query string values into something useful for query execution
    class LiteralInput
      def self.coerce(type, value, variables)
        if value.is_a?(Language::Nodes::VariableIdentifier)
          variables[value.name]
        elsif value.nil?
          nil
        else
          LiteralKindCoercers::STRATEGIES.fetch(type.kind).coerce(value, type, variables)
        end
      end

      def self.from_arguments(ast_arguments, argument_defns, variables)
        values_hash = {}
        argument_defns.each do |arg_name, arg_defn|
          ast_arg = ast_arguments.find { |ast_arg| ast_arg.name == arg_name }
          arg_value = nil
          if ast_arg
            arg_value = coerce(arg_defn.type, ast_arg.value, variables)
          end
          if arg_value.nil?
            arg_value = arg_defn.default_value
          end
          values_hash[arg_name] = arg_value
        end
        GraphQL::Query::Arguments.new(values_hash)
      end

      module LiteralKindCoercers
        module NonNullLiteral
          def self.coerce(value, type, variables)
            LiteralInput.coerce(type.of_type, value, variables)
          end
        end

        module ListLiteral
          def self.coerce(value, type, variables)
            if value.is_a?(Array)
              value.map{ |element_ast| LiteralInput.coerce(type.of_type, element_ast, variables) }
            else
              [LiteralInput.coerce(type.of_type, value, variables)]
            end
          end
        end

        module InputObjectLiteral
          def self.coerce(value, type, variables)
            hash = {}
            value.arguments.each do |arg|
              field_type = type.input_fields[arg.name].type
              hash[arg.name] = LiteralInput.coerce(field_type, arg.value, variables)
            end
            type.input_fields.each do |arg_name, arg_defn|
              if hash[arg_name].nil?
                value = LiteralInput.coerce(arg_defn.type, arg_defn.default_value, variables)
                if !value.nil?
                  hash[arg_name] = value
                end
              end
            end
            Arguments.new(hash)
          end
        end

        module EnumLiteral
          def self.coerce(value, type, variables)
            type.coerce_input(value.name)
          end
        end

        module ScalarLiteral
          def self.coerce(value, type, variables)
            type.coerce_input(value)
          end
        end

        STRATEGIES = {
          TypeKinds::NON_NULL =>     NonNullLiteral,
          TypeKinds::LIST =>         ListLiteral,
          TypeKinds::INPUT_OBJECT => InputObjectLiteral,
          TypeKinds::ENUM =>         EnumLiteral,
          TypeKinds::SCALAR =>       ScalarLiteral,
        }
      end
      private_constant :LiteralKindCoercers
    end
  end
end
