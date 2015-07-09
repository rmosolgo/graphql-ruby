class GraphQL::TypeField < GraphQL::AbstractField
  def initialize(schema)
    @schema = schema
  end

  def type
    GraphQL::TypeType
  end

  def resolve(object, arguments, context)
    type_name = arguments["name"]
    @schema.types[type_name]
  end
end
