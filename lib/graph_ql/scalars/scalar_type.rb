# The parent type for scalars, eg {GraphQL::STRING_TYPE}, {GraphQL::INT_TYPE}
#
class GraphQL::ScalarType < GraphQL::ObjectType
  def kind
    GraphQL::TypeKinds::SCALAR
  end
end
