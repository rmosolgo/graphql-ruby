class GraphQL::AccessFieldDefiner
  def string(name, desc)
    GraphQL::AccessField.new(type: GraphQL::StringType.new, property: name, description: desc)
  end

  def string!(name, desc)
    GraphQL::NonNullField.new(field: string(name, desc))
  end
end
