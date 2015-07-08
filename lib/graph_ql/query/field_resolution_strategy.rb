class GraphQL::Query::FieldResolutionStrategy
  FIELD_TYPE_KIND_STRATEGIES = {
    GraphQL::TypeKinds::SCALAR => :coerce_value,
    GraphQL::TypeKinds::LIST => :map_value,
    GraphQL::TypeKinds::OBJECT => :resolve_selections,
  }

  attr_reader :result, :result_name
  def initialize(ast_field, type, target, operation_resolver)
    arguments = Arguments.new(ast_field.arguments, operation_resolver.variables).to_h
    field = type.fields[ast_field.name]
    value = field.resolve(target, arguments, operation_resolver.context)
    strategy_method = FIELD_TYPE_KIND_STRATEGIES[field.type.kind]
    result_value = send(strategy_method, field.type, value, ast_field, operation_resolver)
    result_name = ast_field.alias || ast_field.name
    @result = { result_name => result_value}
  end

  private

  def coerce_value(field_type, value, ast_field, operation_resolver)
    field_type.coerce(value)
  end

  def map_value(field_type, value, ast_field, operation_resolver)
    list_of_type = field_type.of_type
    strategy_method = FIELD_TYPE_KIND_STRATEGIES[list_of_type.kind]
    value.map do |item|
      send(strategy_method, list_of_type, item, ast_field, operation_resolver)
    end
  end

  def resolve_selections(field_type, value, ast_field, operation_resolver)
    resolver = GraphQL::Query::SelectionResolver.new(value, field_type, ast_field.selections, operation_resolver)
    resolver.result
  end
  # Creates a plain hash out of arguments, looking up variables if necessary
  class Arguments
    attr_reader :to_h
    def initialize(ast_arguments, variables)
      @to_h = ast_arguments.reduce({}) do |memo, arg|
        value = arg.value
        if value.is_a?(GraphQL::Nodes::VariableIdentifier)
          value = variables[value.name]
        elsif value.is_a?(GraphQL::Nodes::Enum)
          value = value.name
        end
        memo[arg.name] = value
        memo
      end
    end
  end
end
