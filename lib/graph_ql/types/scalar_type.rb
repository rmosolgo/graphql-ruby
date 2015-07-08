class GraphQL::ScalarType < GraphQL::ObjectType
  def kind
    GraphQL::TypeKinds::SCALAR
  end
end
