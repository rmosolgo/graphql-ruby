class GraphQL::Interface < GraphQL::ObjectType
  include GraphQL::NonNullWithBang
  def definer_for_type(type)
    @definer ||= GraphQL::InterfaceFieldDefiner.new
  end
end
