# Anything can be a Field as long as it responds to:
#   - #name: String the name to access this field in a query
#   - #type: Type returned by this field's resolve function
#   - #description: String
#   - #resolve(object, arguments, context): Object of Type `type`
#   - #arguments: ???
#   - #deprecation_reason
class GraphQL::AbstractField
  def name
    raise NotImplementedError, "#{self.class.name}#name should return the name for accessing this field"
  end

  def type
    raise NotImplementedError, "#{self.class.name}#type should return the type class which this field returns"
  end

  def description
    raise NotImplementedError, "#{self.class.name}#description should return this field's description"
  end


  def resolve(object, arguments, context)
    raise NotImplementedError, "#{self.class.name}#resolve(object, arguments, context) should execute this field for object"
  end

  def arguments
    {}
  end

  def deprecated?
    !!deprecation_reason
  end

  def deprecation_reason
    nil
  end
end
