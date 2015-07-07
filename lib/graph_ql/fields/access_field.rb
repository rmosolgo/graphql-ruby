# Implement {AbstractField} by calling {property} on its object
# and returning the result.
class GraphQL::AccessField
  attr_reader :type, :description
  def initialize(type:, property:, description:)
    @type = type
    @property = property
    @description = description
  end

  def resolve(object, arguments, context)
    p "Obj: #{object}, #{@property}"
    object.send(@property)
  end
end
