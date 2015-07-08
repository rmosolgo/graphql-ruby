class GraphQL::AbstractField
  def type
    raise NotImplementedError, "#type should return the type class which this field returns"
  end

  def description
    raise NotImplementedError, "#description should return this field's description"
  end

  def resolve(object, arguments, context)
    raise NotImplementedError, "#resolve(object, arguments) should execute this field for object"
  end
end
