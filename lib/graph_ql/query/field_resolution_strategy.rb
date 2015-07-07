class GraphQL::Query::FieldResolutionStrategy
  attr_reader :result, :result_name
  def initialize(ast_field, type, target, operation_resolver)
    arguments = Arguments.new(ast_field.arguments, operation_resolver.variables).to_h
    field = type.fields[ast_field.name]
    value = field.resolve(target, arguments, operation_resolver.context)

    if GraphQL::SCALAR_TYPES.include?(field.type)
      result_value = field.type.coerce(value)
    else
      resolver = GraphQL::Query::SelectionResolver.new(value, field.type, ast_field.selections, operation_resolver)
      result_value = resolver.result
    end

    result_name = ast_field.alias || ast_field.name
    @result = { result_name => result_value}
  end

  # Creates a plain hash out of arguments, looking up variables if necessary
  class Arguments
    attr_reader :to_h
    def initialize(ast_arguments, variables)
      @to_h = ast_arguments.reduce({}) do |memo, arg|
        value = arg.value
        if value.is_a?(GraphQL::Syntax::VariableIdentifier)
          value = variables[value.name]
        end
        memo[arg.name] = value
        memo
      end
    end
  end
end
