class GraphQL::Query::FieldResolutionStrategy
  attr_reader :result, :result_value

  def initialize(ast_field, parent_type, target, query)
    field_name = ast_field.name
    field = query.schema.get_field(parent_type, field_name) || raise("No field found on #{parent_type.name} '#{parent_type}' for '#{field_name}'")
    arguments = GraphQL::Query::Arguments.new(ast_field.arguments, field.arguments, query.variables)
    value = field.resolve(target, arguments, query.context)
    if value.nil?
      @result_value = value
    else
      if value == GraphQL::Query::DEFAULT_RESOLVE
        begin
          value = target.send(field_name)
        rescue NoMethodError => err
          raise("Couldn't resolve field '#{field_name}' to #{target.class} '#{target}' (resulted in #{err})")
        end
      end
      resolved_type = field.type.kind.resolve(field.type, value)
      strategy_class = GraphQL::Query::ValueResolution.get_strategy_for_kind(resolved_type.kind)
      result_strategy = strategy_class.new(value, resolved_type, target, parent_type, ast_field, query)
      @result_value = result_strategy.resolve
    end
    result_name = ast_field.alias || ast_field.name
    @result = { result_name => @result_value}
  end
end
