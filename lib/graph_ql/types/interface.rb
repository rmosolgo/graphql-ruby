class GraphQL::Interface < GraphQL::ObjectType
  def kind
    GraphQL::TypeKinds::INTERFACE
  end

  def possible_types
    @possible_types ||= []
  end

  # Might have to override this in your own interface
  def resolve_type(object)
    @possible_types.find {|t| t.name == object.class.name }
  end
end
