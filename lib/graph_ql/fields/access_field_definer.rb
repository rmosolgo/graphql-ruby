class GraphQL::AccessFieldDefiner
  def string(name, desc)
    GraphQL::AccessField.new(type: GraphQL::STRING_TYPE, property: name, description: desc)
  end

  def string!(name, desc)
    GraphQL::NonNullField.new(field: string(name, desc))
  end

  def float!(name, desc)
  end
end
