# Implement {AbstractField} by calling the field name on its object
# and returning the result.
class GraphQL::AccessField < GraphQL::AbstractField
  attr_accessor :name, :type
  attr_reader :description, :arguments, :deprecation_reason
  def initialize(type:, arguments:, description:, property: nil, deprecation_reason: nil)
    @type = type
    @arguments = arguments
    @description = description
    @property = property
    @deprecation_reason = deprecation_reason
  end

  def resolve(object, args, context)
    @property.nil? ? GraphQL::Query::DEFAULT_RESOLVE : object.send(@property)
  end
end
