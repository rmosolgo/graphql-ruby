class GraphQL::TypeDefiner
  TYPES = {
    Int:     GraphQL::INT_TYPE,
    String:  GraphQL::STRING_TYPE,
    Float:   GraphQL::FLOAT_TYPE,
    Boolean: GraphQL::BOOLEAN_TYPE,
  }

  TYPES.each do |method_name, type|
    define_method(method_name) { type }
  end

  def [](type)
    GraphQL::ListType.new(of_type: type)
  end
end
