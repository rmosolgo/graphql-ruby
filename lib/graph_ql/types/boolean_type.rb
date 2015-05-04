class GraphQL::Types::BooleanType < GraphQL::Types::ObjectType
  exposes("TrueClass", "FalseClass")
  desc("True or false")
end