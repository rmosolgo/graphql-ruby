class GraphQL::Schema::UnionValidator
  def validate(union, errors)
    name = union.name
    types = union.possible_types
    if types.length < 2
      errors << "Union #{name} must be defined with 2 or more types, not #{types.length}"
    end

    non_object_types = types.select {|t| !t.kind.object?}
    if non_object_types.any?
      types_string = non_object_types.map(&:name).join(", ")
      errors << "Unions can only consist of Object types, but #{name} has non-object types: #{types_string}"
    end
  end
end
