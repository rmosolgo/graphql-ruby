class GraphQL::Types::ObjectType < GraphQL::Node
  exposes("Object")
  def as_result
    target
  end
end