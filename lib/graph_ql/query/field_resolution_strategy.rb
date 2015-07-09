class GraphQL::Query::FieldResolutionStrategy
  FIELD_TYPE_KIND_STRATEGIES = {
    GraphQL::TypeKinds::SCALAR =>   :coerce_value,
    GraphQL::TypeKinds::LIST =>     :map_value,
    GraphQL::TypeKinds::OBJECT =>   :resolve_selections,
    GraphQL::TypeKinds::ENUM =>     :return_name_as_string,
    GraphQL::TypeKinds::NON_NULL => :get_wrapped_type,
  }

  attr_reader :result, :result_name

  def initialize(ast_field, type, target, operation_resolver)
    arguments = Arguments.new(ast_field.arguments, operation_resolver.variables).to_h
    field = type.fields[ast_field.name] || raise("No field found on #{type.name} for '#{ast_field.name}'")
    value = field.resolve(target, arguments, operation_resolver.context)
    if value == GraphQL::Query::DEFAULT_RESOLVE
      value = if arguments.empty?
        target.send(ast_field.name)
      else
        target.send(ast_field.name, arguments)
      end
    end
    result_value = resolve_with_strategy(field.type, value, ast_field, operation_resolver)
    result_name = ast_field.alias || ast_field.name
    @result = { result_name => result_value}
  end

  private
  def resolve_with_strategy(field_type, value, ast_field, operation_resolver)
    strategy_method = FIELD_TYPE_KIND_STRATEGIES[field_type.kind] || raise("No strategy found for #{field_type.kind}")
    send(strategy_method, field_type, value, ast_field, operation_resolver)
  end

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

  def return_name_as_string(field_type, value, ast_field, operation_resolver)
    value.to_s
  end

  def get_wrapped_type(field_type, value, ast_field, operation_resolver)
    wrapped_type = field_type.of_type
    resolve_with_strategy(wrapped_type, value, ast_field, operation_resolver)
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
