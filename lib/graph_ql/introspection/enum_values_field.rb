GraphQL::EnumValuesField = GraphQL::Field.new do |f|
  f.description 'Values for this enum'
  f.type GraphQL::ListType.new(of_type: GraphQL::NonNullType.new(of_type: GraphQL::EnumValueType))
  f.arguments(includeDeprecated: { type: GraphQL::BOOLEAN_TYPE, default_value: false })
  f.resolve lambda  { |object, arguments, _context|
    return nil if object.kind != GraphQL::TypeKinds::ENUM
    fields = object.values.values
    unless arguments['includeDeprecated']
      fields = fields.select { |f| !f.deprecated? }
    end
    fields
  }
end
