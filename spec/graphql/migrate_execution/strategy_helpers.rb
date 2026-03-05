module GraphQLMigrateExecutionStrategyHelpers
  def add_future(ruby_src)
    field_definition = parse_to_field_definition(ruby_src)
    new_source = ruby_src.dup
    @strategy_class.new.add_future(field_definition, new_source)
    new_source
  end

  def remove_legacy(ruby_src)
    field_definition = parse_to_field_definition(ruby_src)
    new_source = ruby_src.dup
    @strategy_class.new.remove_legacy(field_definition, new_source)
    new_source
  end

  def parse_to_field_definition(ruby_src)
    action = GraphQL::MigrateExecution::Action.new(nil, "app.rb", ruby_src)
    action.run
    action.type_definitions.each_value.first.field_definitions.each_value.first
  end
end
