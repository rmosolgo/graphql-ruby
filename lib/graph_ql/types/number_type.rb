class GraphQL::Types::NumberType < GraphQL::Types::ObjectType
  exposes("Numeric")
  desc("A number (float or int)")
end