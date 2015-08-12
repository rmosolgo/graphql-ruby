class GraphQL::Schema::SchemaValidator
  def validate(schema)
    errors = []
    schema.types.each do |name, type|
      type_validator = GraphQL::Schema::TypeValidator.new
      type_validator.validate(type, errors)
    end
    errors
  end
end
