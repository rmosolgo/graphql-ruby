class GraphQL::Types::ObjectType < GraphQL::Node
  type "object"
  exposes("Object")
  def as_result
    target
  end
end