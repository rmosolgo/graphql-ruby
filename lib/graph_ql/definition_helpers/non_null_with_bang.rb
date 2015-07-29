# Wrap the object in NonNullType in response to `!`
# @example required Int type
#   !GraphQL::INT_TYPE
#
module GraphQL::NonNullWithBang
  # Make the type non-null
  # @return [GraphQL::NonNullType] a non-null type which wraps the original type
  def !
    GraphQL::NonNullType.new(of_type: self)
  end
end
