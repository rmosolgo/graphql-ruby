# Anything can be a Field as long as it responds to:
#   - #type: Type returned by this field's resolve function
#   - #description: String
#   - #resolve(object, arguments, context): Object of Type `type`
#   - #arguments: ???
class GraphQL::AbstractField
  def type
    raise NotImplementedError, "#{self.class.name}#type should return the type class which this field returns"
  end

  def description
    raise NotImplementedError, "#{self.class.name}#description should return this field's description"
  end

  def resolve(object, arguments, context)
    raise NotImplementedError, "#{self.class.name}#resolve(object, arguments, context) should execute this field for object"
  end
end
