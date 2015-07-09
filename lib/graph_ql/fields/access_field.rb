# Implement {AbstractField} by calling the field name on its object
# and returning the result.
class GraphQL::AccessField
  attr_reader :type, :description, :arguments
  def initialize(type:, arguments:, description:)
    @type = type
    @arguments = arguments
    @description = description
  end

  def resolve(object, args, context)
    GraphQL::Query::DEFAULT_RESOLVE
  end
end
