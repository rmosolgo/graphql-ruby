class GraphQL::StaticValidation::VariableUsagesAreAllowed
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    # holds { name => ast_node } pairs
    declared_variables = {}

    context.visitor[GraphQL::Language::Nodes::OperationDefinition] << -> (node, parent) {
      declared_variables = node.variables.each_with_object({}) { |var, memo| memo[var.name] = var }
    }

    context.visitor[GraphQL::Language::Nodes::Argument] << -> (node, parent) {
      return if !node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
      if parent.is_a?(GraphQL::Language::Nodes::Field)
        arguments = context.field_definition.arguments
      elsif parent.is_a?(GraphQL::Language::Nodes::Directive)
        arguments = context.directive_definition.arguments
      end
      var_defn_ast = declared_variables[node.value.name]
      validate_usage(arguments, node, var_defn_ast, context)
    }
  end

  private

  def validate_usage(arguments, arg_node, ast_var, context)
    var_type = to_query_type(ast_var.type, context.schema.types)
    if !ast_var.default_value.nil?
      var_type = GraphQL::NonNullType.new(of_type: var_type)
    end

    arg_defn = arguments[arg_node.name]
    if var_type != arg_defn.type
      context.errors << message("Type mismatch on variable $#{ast_var.name} and argument #{arg_node.name} (#{var_type.to_s} / #{arg_defn.type.to_s})", arg_node)
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
end
