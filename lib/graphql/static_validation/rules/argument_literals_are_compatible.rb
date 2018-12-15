# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class ArgumentLiteralsAreCompatible < GraphQL::StaticValidation::ArgumentsValidator
      def validate_node(parent, node, defn, context)
        return if node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
        arg_defn = defn.arguments[node.name]
        return unless arg_defn
        if !context.schema.error_bubbling
          begin
            context.valid_literal?(node.value, arg_defn.type)
          rescue GraphQL::CoercionError, GraphQL::LiteralValidationError => err
            if err.is_a?(GraphQL::LiteralValidationError)
              # check to see if the ast node that caused the error to be raised is
              # the same as the node we were checking here.
              matched = if arg_defn.type.kind.list?
                # for a list we claim an error if the node is contained in our list
                node.value.include?(err.ast_value)
              elsif arg_defn.type.kind.input_object? && node.value.is_a?(GraphQL::Language::Nodes::InputObject)
                # for an input object we check the arguments
                node.value.arguments.include?(err.ast_value)
              else
                # otherwise we just check equality
                node.value == (err.ast_value)
              end
              return false unless matched
            end

            error_message = err.message if err.is_a? GraphQL::CoercionError
            error_message ||= begin
              kind_of_node = node_type(parent)
              error_arg_name = parent_name(parent, defn)
              "Argument '#{node.name}' on #{kind_of_node} '#{error_arg_name}' has an invalid value. Expected type '#{arg_defn.type}'."
            end

            context.errors << message(error_message, parent, context: context)
          end
         else
           begin
             valid = context.valid_literal?(node.value, arg_defn.type)
           rescue GraphQL::CoercionError => err
             error_message = err.message
           end

          return if valid

          error_message ||= begin
            kind_of_node = node_type(parent)
            error_arg_name = parent_name(parent, defn)
            "Argument '#{node.name}' on #{kind_of_node} '#{error_arg_name}' has an invalid value. Expected type '#{arg_defn.type}'."
          end

          context.errors << message(error_message, parent, context: context)
        end
      end
    end
  end
end
