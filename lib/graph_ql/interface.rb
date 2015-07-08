class GraphQL::Interface < GraphQL::ObjectType
  def definer_for_type(type)
    @definer ||= GraphQL::InterfaceFieldDefiner.new
  end
end
