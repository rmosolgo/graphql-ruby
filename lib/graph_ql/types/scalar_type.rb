class GraphQL::ScalarType < GraphQL::ObjectType
  def kind
    GraphQL::TypeKinds::SCALAR
  end

  def to_s
    "<GraphQL::ScalarType #{name} >"
  end
end
