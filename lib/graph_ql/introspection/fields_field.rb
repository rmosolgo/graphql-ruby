class GraphQL::FieldsField < GraphQL::AbstractField
  def description
    "List of fields on this object"
  end

  def type
    GraphQL::ListType.new(of_type: GraphQL::NonNullType.new(of_type: GraphQL::FieldType))
  end

  def arguments
    {includeDeprecated: {type: GraphQL::BOOLEAN_TYPE, default_value: false}}
  end

  def resolve(object, arguments, context)
    fields = object.send(:fields).values
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecated? }
    end
    fields
  end
end
