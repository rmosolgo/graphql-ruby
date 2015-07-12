class GraphQL::Query::FieldResolutionStrategy
  UNRESOLVED_TYPE_KINDS = [GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE]
  attr_reader :result, :result_value

  def initialize(ast_field, parent_type, target, operation_resolver)
    arguments = GraphQL::Query::Arguments.new(ast_field.arguments, operation_resolver.variables).to_h
    field_name = ast_field.name
    field = parent_type.fields[field_name] || raise("No field found on #{parent_type.name} '#{parent_type}' for '#{field_name}'")
    value = field.resolve(target, arguments, operation_resolver.context)
    if value.nil?
      @result_value = value
    else
      if value == GraphQL::Query::DEFAULT_RESOLVE
        begin
          value = target.send(field_name)
        rescue NoMethodError => e
          raise("Couldn't resolve field '#{field_name}' to #{target.class} '#{target}' (resulted in NoMethodError)")
        end
      end

      if UNRESOLVED_TYPE_KINDS.include?(field.type.kind)
        resolved_type = field.type.resolve_type(value)
      else
        resolved_type = field.type
      end

      strategy_class = FIELD_TYPE_KIND_STRATEGIES[resolved_type.kind] || raise("No strategy found for #{resolved_type.kind}")
      result_strategy = strategy_class.new(value, resolved_type, target, parent_type, ast_field, operation_resolver)
      @result_value = result_strategy.result
    end
    result_name = ast_field.alias || ast_field.name
    @result = { result_name => @result_value}
  end

  class ScalarResolutionStrategy
    attr_reader :result
    def initialize(value, field_type, target, parent_type, ast_field, operation_resolver)
      @result = field_type.coerce(value)
    end
  end

  class ListResolutionStrategy
    attr_reader :result
    def initialize(value, field_type, target, parent_type, ast_field, operation_resolver)
      wrapped_type = field_type.of_type
      strategy_class = FIELD_TYPE_KIND_STRATEGIES[wrapped_type.kind]
      @result = value.map do |item|
        inner_strategy = strategy_class.new(item, wrapped_type, target, parent_type, ast_field, operation_resolver)
        inner_strategy.result
      end
    end
  end

  class ObjectResolutionStrategy
    attr_reader :result
    def initialize(value, field_type, target, parent_type, ast_field, operation_resolver)
      resolver = GraphQL::Query::SelectionResolver.new(value, field_type, ast_field.selections, operation_resolver)
      @result = resolver.result
    end
  end


  class EnumResolutionStrategy
    attr_reader :result
    def initialize(value, field_type, target, parent_type, ast_field, operation_resolver)
      @result = value.to_s
    end
  end

  class NonNullResolutionStrategy
    attr_reader :result
    def initialize(value, field_type, target, parent_type, ast_field, operation_resolver)
      wrapped_type = field_type.of_type
      strategy_class = FIELD_TYPE_KIND_STRATEGIES[wrapped_type.kind]
      inner_strategy = strategy_class.new(value, wrapped_type, target, parent_type, ast_field, operation_resolver)
      @result = inner_strategy.result
    end
  end

  private

  FIELD_TYPE_KIND_STRATEGIES = {
    GraphQL::TypeKinds::SCALAR =>     ScalarResolutionStrategy,
    GraphQL::TypeKinds::LIST =>       ListResolutionStrategy,
    GraphQL::TypeKinds::OBJECT =>     ObjectResolutionStrategy,
    GraphQL::TypeKinds::ENUM =>       EnumResolutionStrategy,
    GraphQL::TypeKinds::NON_NULL =>   NonNullResolutionStrategy,
  }
end
