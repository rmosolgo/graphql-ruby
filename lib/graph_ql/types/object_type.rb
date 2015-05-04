class GraphQL::Types::ObjectType < GraphQL::Node
  exposes("Object")
  desc("Any object")
  def as_result
    target
  end
end