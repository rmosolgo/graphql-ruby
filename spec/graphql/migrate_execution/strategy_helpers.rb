module GraphQLMigrateExecutionStrategyHelpers
  def add_future(ruby_src)
    apply_action_method(ruby_src, :add_future)
  end

  def remove_legacy(ruby_src)
    apply_action_method(ruby_src, :remove_legacy)
  end

  def apply_action_method(ruby_src, action_method)
    action = GraphQL::MigrateExecution::Action.new(nil, "app.rb", ruby_src)
    action.run
    field_definitions = action.type_definitions.each_value.first.field_definitions.values
    new_source = ruby_src.dup
    field_definitions.each do |field_definition|
      @strategy_class.new.public_send(action_method, field_definition, new_source)
    end
    new_source
  end
end
