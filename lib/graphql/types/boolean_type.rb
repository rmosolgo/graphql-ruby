class GraphQL::Types::BooleanType < GraphQL::Types::ObjectType
  type("boolean")
  exposes("TrueClass", "FalseClass")
end