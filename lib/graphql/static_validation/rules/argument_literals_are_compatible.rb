# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class ArgumentLiteralsAreCompatible < GraphQL::StaticValidation::ArgumentsValidator
      def validate_node(parent, node, defn, context)
        return if node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
        arg_defn = defn.arguments[node.name]
        return unless arg_defn

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
