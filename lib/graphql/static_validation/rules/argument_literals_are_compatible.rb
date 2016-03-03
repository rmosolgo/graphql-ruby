module GraphQL
  module StaticValidation
    class ArgumentLiteralsAreCompatible < GraphQL::StaticValidation::ArgumentsValidator
      def validate_node(parent, node, defn, context)
        return if node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
        validator = GraphQL::StaticValidation::LiteralValidator.new
        arg_defn = defn.arguments[node.name]
        return unless arg_defn
        valid = validator.validate(node.value, arg_defn.type)
        if !valid
          kind_of_node = node_type(parent)
          error_arg_name = parent_name(parent, defn)
          context.errors << message("Argument '#{node.name}' on #{kind_of_node} '#{error_arg_name}' has an invalid value", parent)
        end
      end
    end
  end
end
