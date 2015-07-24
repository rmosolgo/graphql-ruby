# Wrap the object in NonNullType in response to `!`
# @example required Int type
#   !GraphQL::INT_TYPE
#
module GraphQL::NonNullWithBang
  def !
    GraphQL::NonNullType.new(of_type: self)
  end
end
