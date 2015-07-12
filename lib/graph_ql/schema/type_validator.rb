class GraphQL::Schema::TypeValidator
  def validate(type, errors)
    implementation = GraphQL::Schema::ImplementationValidator.new(type, as: "Type", errors: errors)
    implementation.must_respond_to(:name)
    implementation.must_respond_to(:kind)
    if !type.kind.union?
      implementation.must_respond_to(:description)
    end
    if type.kind.fields?
      implementation.must_respond_to(:fields)
    end
    if type.kind.object?
      implementation.must_respond_to(:interfaces)
    end
    if type.kind.union?
      GraphQL::Schema::UnionValidator.new.validate(type, errors)
    end
  end
end
