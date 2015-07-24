class GraphQL::StaticValidation::VariablesAreUsedAndDefined
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    # holds { name => used? } pairs
    declared_variables = {}

    context.visitor[GraphQL::Nodes::OperationDefinition] << -> (node, parent) {
      declared_variables = node.variables.each_with_object({}) { |var, memo| memo[var.name] = false }
    }

    context.visitor[GraphQL::Nodes::VariableIdentifier] << -> (node, parent) {
      if declared_variables.key?(node.name)
        declared_variables[node.name] = true
      else
        context.errors << message("Variable $#{node.name} is used but not declared", node)
        GraphQL::Visitor::SKIP
      end
    }

    context.visitor[GraphQL::Nodes::OperationDefinition].leave << -> (node, parent) {
      unused_variables = declared_variables
        .select { |name, used| !used }
        .keys

      unused_variables.each do |var_name|
        context.errors << message("Variable $#{var_name} is declared but not used", node)
      end
    }
  end
end
