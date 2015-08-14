class GraphQL::Schema::TypeValidator
  def validate(type, errors)
    own_errors = []
    implementation = GraphQL::Schema::ImplementationValidator.new(type, as: "Type", errors: own_errors)
    implementation.must_respond_to(:name)
    implementation.must_respond_to(:kind)
    if own_errors.any? # if no name or kind, abort!
      errors.push(*own_errors)
      return
    end

    type_name = type.name
    kind_name = type.kind.name

    implementation.must_respond_to(:description, as: kind_name)
    each_item_validator = GraphQL::Schema::EachItemValidator.new(own_errors)

    if type.kind.fields?
      field_validator = GraphQL::Schema::FieldValidator.new
      implementation.must_respond_to(:fields, as: kind_name) do |fields|
        each_item_validator.validate(fields.keys, as: "#{type.name}.fields keys", must_be: "Strings") { |k| k.is_a?(String) }

        fields.values.each do |field|
          field_validator.validate(field, own_errors)
        end
      end
    end

    if type.kind.resolves?
      implementation.must_respond_to(:resolve_type)
      implementation.must_respond_to(:possible_types, as: kind_name) do |possible_types|
        each_item_validator.validate(possible_types, as: "#{type_name}.possible_types", must_be: "objects") { |t| t.kind.object? }
      end
    end

    if type.kind.object?
      implementation.must_respond_to(:interfaces, as: kind_name) do |interfaces|
        each_item_validator.validate(interfaces, as: "#{type_name}.interfaces", must_be: "interfaces") { |t| t.kind.interface? }
      end
    end

    if type.kind.input_object?
      implementation.must_respond_to(:input_fields, as: kind_name)
    end

    if type.kind.union?
      union_types = type.possible_types
      if union_types.length < 2
        own_errors << "Union #{type_name} must be defined with 2 or more types, not #{union_types.length}"
      end
    end
    errors.push(*own_errors)
  end
end
