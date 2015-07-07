# Implement {AbstractField} by calling {property} on its object
# and returning the result.
class GraphQL::AccessField
  attr_reader :type, :description, :property
  def initialize(type:, property:, description:)
    @type = type
    @property = property
    @description = description
  end

  def resolve(object, arguments, context)
    object.send(property)
  end

  def !
    GraphQL::NonNullField.new(field: self)
  end
end
