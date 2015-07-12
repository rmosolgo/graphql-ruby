class GraphQL::Schema::TypeValidator
  def validate(type, errors)
    implementation = GraphQL::Schema::ImplementationValidator.new(type, as: "Type", errors: errors)
    implementation.must_respond_to(:name)
    implementation.must_respond_to(:kind)
    kind_name = type.kind.name

    implementation.must_respond_to(:description, as: kind_name)
    if type.kind.fields?
      implementation.must_respond_to(:fields, as: kind_name)
      field_validator = GraphQL::Schema::FieldValidator.new
      type.fields.values.each do |field|
        field_validator.validate(field, errors)
      end
    end
    if type.kind.resolves?
      implementation.must_respond_to(:possible_types, as: kind_name)
    end
    if type.kind.object?
      implementation.must_respond_to(:interfaces, as: kind_name)
    end
    if type.kind.input_object?
      implementation.must_respond_to(:input_fields, as: kind_name)
    end
    if type.kind.union?
      GraphQL::Schema::UnionValidator.new.validate(type, errors)
    end
  end
end
