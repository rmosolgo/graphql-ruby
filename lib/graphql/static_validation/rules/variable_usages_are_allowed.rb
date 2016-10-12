module GraphQL
  module StaticValidation
    class VariableUsagesAreAllowed
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        # holds { name => ast_node } pairs
        declared_variables = {}

        context.visitor[GraphQL::Language::Nodes::OperationDefinition] << ->(node, parent) {
          declared_variables = node.variables.each_with_object({}) { |var, memo| memo[var.name] = var }
        }

        context.visitor[GraphQL::Language::Nodes::Argument] << ->(node, parent) {
          return if !node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          if parent.is_a?(GraphQL::Language::Nodes::Field)
            arguments = context.field_definition.arguments
          elsif parent.is_a?(GraphQL::Language::Nodes::Directive)
            arguments = context.directive_definition.arguments
          elsif parent.is_a?(GraphQL::Language::Nodes::InputObject)
            arguments = context.argument_definition.type.unwrap.input_fields
          else
            raise("Unexpected argument parent: #{parent}")
          end
          var_defn_ast = declared_variables[node.value.name]
          # Might be undefined :(
          # VariablesAreUsedAndDefined can't finalize its search until the end of the document.
          var_defn_ast && validate_usage(arguments, node, var_defn_ast, context)
        }
      end

      private

      def validate_usage(arguments, arg_node, ast_var, context)
        var_type = to_query_type(ast_var.type, context.schema.types)
        if !ast_var.default_value.nil?
          var_type = GraphQL::NonNullType.new(of_type: var_type)
        end

        arg_defn = arguments[arg_node.name]
        arg_defn_type = arg_defn.type

        var_inner_type = var_type.unwrap
        arg_inner_type = arg_defn_type.unwrap

        if var_inner_type != arg_inner_type
          context.errors << create_error("Type mismatch", var_type, ast_var, arg_defn, arg_node, context)
        elsif list_dimension(var_type) != list_dimension(arg_defn_type)
          context.errors << create_error("List dimension mismatch", var_type, ast_var, arg_defn, arg_node, context)
        elsif !non_null_levels_match(arg_defn_type, var_type)
          context.errors << create_error("Nullability mismatch", var_type, ast_var, arg_defn, arg_node, context)
        end
      end

      def to_query_type(ast_type, types)
        if ast_type.is_a?(GraphQL::Language::Nodes::NonNullType)
          GraphQL::NonNullType.new(of_type: to_query_type(ast_type.of_type, types))
        elsif ast_type.is_a?(GraphQL::Language::Nodes::ListType)
          GraphQL::ListType.new(of_type: to_query_type(ast_type.of_type, types))
        else
          types[ast_type.name]
        end
      end

      def create_error(error_message, var_type, ast_var, arg_defn, arg_node, context)
        message("#{error_message} on variable $#{ast_var.name} and argument #{arg_node.name} (#{var_type.to_s} / #{arg_defn.type.to_s})", arg_node, context: context)
      end

      def list_dimension(type)
        if type.kind.list?
          1 + list_dimension(type.of_type)
        elsif type.kind.non_null?
          list_dimension(type.of_type)
        else
          0
        end
      end

      def non_null_levels_match(arg_type, var_type)
        if arg_type.kind.non_null? && !var_type.kind.non_null?
          false
        elsif arg_type.kind.wraps? && var_type.kind.wraps?
          # If var_type is a non-null wrapper for a type, and arg_type is nullable, peel off the wrapper
          # That way, a var_type of `[DairyAnimal]!` works with an arg_type of `[DairyAnimal]`
          if var_type.kind.non_null? && !arg_type.kind.non_null?
            var_type = var_type.of_type
          end
          non_null_levels_match(arg_type.of_type, var_type.of_type)
        else
          true
        end
      end
    end
  end
end
