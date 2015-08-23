class GraphQL::Query::FieldResolutionStrategy
  attr_reader :field, :arguments, :ast_field, :query, :target, :result_name, :parent_type, :target

  def initialize(ast_field, parent_type, target, query)
    @ast_field = ast_field
    @parent_type = parent_type
    @target = target
    @query = query
    @field = query.schema.get_field(parent_type, ast_field.name) || raise("No field found on #{parent_type.name} '#{parent_type}' for '#{ast_field.name}'")
    @arguments = GraphQL::Query::Arguments.new(ast_field.arguments, field.arguments, query.variables)
  end

  def result
    result_name = ast_field.alias || ast_field.name
    { result_name => result_value}
  end

  private

  def result_value
    value = field.resolve(target, arguments, query.context)
    return nil if value.nil?

    if value == GraphQL::Query::DEFAULT_RESOLVE
      begin
        value = target.public_send(ast_field.name)
      rescue NoMethodError => err
        raise("Couldn't resolve field '#{ast_field.name}' to #{target.class} '#{target}' (resulted in #{err})")
      end
    end

    resolved_type = field.type.kind.resolve(field.type, value)
    strategy_class = GraphQL::Query::ValueResolution.get_strategy_for_kind(resolved_type.kind)
    result_strategy = strategy_class.new(value, resolved_type, target, parent_type, ast_field, query)
    result_strategy.result
  end
end
