class GraphQL::Schema::FieldValidator
  def validate(field, errors)
    implementation = GraphQL::Schema::ImplementationValidator.new(field, as: "Field", errors: errors)
    implementation.must_respond_to(:name)
    implementation.must_respond_to(:type)
    implementation.must_respond_to(:description)
    implementation.must_respond_to(:arguments)
    implementation.must_respond_to(:deprecation_reason)
  end
end
