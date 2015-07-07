class GraphQL::Query::FieldResolver
  attr_reader :result, :result_name
  def initialize(ast_field, type, target, operation_resolver)
    @result_name = ast_field.alias || ast_field.name
    # TODO: fetch variables
    arguments = ast_field.arguments.reduce({}) { |m, a| m[a.name] = a.value; m }
    field = type.fields[ast_field.name]
    value = field.resolve(target, arguments, operation_resolver.context)
    if GraphQL::SCALAR_TYPES.include?(field.type)
      @result = field.type.coerce(value)
    else
      resolver = GraphQL::Query::SelectionResolver.new(value, field.type, ast_field.selections, operation_resolver)
      @result = resolver.result
    end

  end
end
