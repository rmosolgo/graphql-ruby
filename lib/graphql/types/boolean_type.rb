class GraphQL::Types::BooleanType < GraphQL::Types::ObjectType
  exposes("TrueClass", "FalseClass")
end