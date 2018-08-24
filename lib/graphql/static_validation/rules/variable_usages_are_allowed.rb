# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class VariableUsagesAreAllowed
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        # holds { name => ast_node } pairs
        declared_variables = {}
        context.visitor[GraphQL::Language::Nodes::OperationDefinition] << -> (node, parent) {
          declared_variables = node.variables.each_with_object({}) { |var, memo| memo[var.name] = var }
        }

        context.visitor[GraphQL::Language::Nodes::Argument] << -> (node, parent) {
          node_values = if node.value.is_a?(Array)
                          node.value
                        else
                          [node.value]
                        end
          node_values = node_values.select { |value| value.is_a? GraphQL::Language::Nodes::VariableIdentifier }

          return if node_values.none?

          arguments = nil
          case parent
          when GraphQL::Language::Nodes::Field
            arguments = context.field_definition.arguments
          when GraphQL::Language::Nodes::Directive
            arguments = context.directive_definition.arguments
          when GraphQL::Language::Nodes::InputObject
            arg_type = context.argument_definition.type.unwrap
            if arg_type.is_a?(GraphQL::InputObjectType)
              arguments = arg_type.input_fields
            end
          else
            raise("Unexpected argument parent: #{parent}")
          end

          node_values.each do |node_value|
            var_defn_ast = declared_variables[node_value.name]
            # Might be undefined :(
            # VariablesAreUsedAndDefined can't finalize its search until the end of the document.
            var_defn_ast && arguments && validate_usage(arguments, node, var_defn_ast, context)
          end
        }
      end

      private

      def validate_usage(arguments, arg_node, ast_var, context)
        var_type = context.schema.type_from_ast(ast_var.type)
        if var_type.nil?
          return
        end
        if !ast_var.default_value.nil?
          unless var_type.is_a?(GraphQL::NonNullType)
            # If the value is required, but the argument is not,
            # and yet there's a non-nil default, then we impliclty
            # make the argument also a required type.

            var_type = GraphQL::NonNullType.new(of_type: var_type)
          end
        end

        arg_defn = arguments[arg_node.name]
        arg_defn_type = arg_defn.type

        var_inner_type = var_type.unwrap
        arg_inner_type = arg_defn_type.unwrap

        var_type = wrap_var_type_with_depth_of_arg(var_type, arg_node)

        if var_inner_type != arg_inner_type
          context.errors << create_error("Type mismatch", var_type, ast_var, arg_defn, arg_node, context)
        elsif list_dimension(var_type) != list_dimension(arg_defn_type)
          context.errors << create_error("List dimension mismatch", var_type, ast_var, arg_defn, arg_node, context)
        elsif !non_null_levels_match(arg_defn_type, var_type)
          context.errors << create_error("Nullability mismatch", var_type, ast_var, arg_defn, arg_node, context)
        end
      end

      def create_error(error_message, var_type, ast_var, arg_defn, arg_node, context)
        message("#{error_message} on variable $#{ast_var.name} and argument #{arg_node.name} (#{var_type.to_s} / #{arg_defn.type.to_s})", arg_node, context: context)
      end

      def wrap_var_type_with_depth_of_arg(var_type, arg_node)
        arg_node_value = arg_node.value
        return var_type unless arg_node_value.is_a?(Array)
        new_var_type = var_type

        depth_of_array(arg_node_value).times do
          # Since the array _is_ present, treat it like a non-null type
          # (It satisfies a non-null requirement AND a nullable requirement)
          new_var_type = new_var_type.to_list_type.to_non_null_type
        end

        new_var_type
      end

      # @return [Integer] Returns the max depth of `array`, or `0` if it isn't an array at all
      def depth_of_array(array)
        case array
        when Array
          max_child_depth = 0
          array.each do |item|
            item_depth = depth_of_array(item)
            if item_depth > max_child_depth
              max_child_depth = item_depth
            end
          end
          1 + max_child_depth
        else
          0
        end
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
