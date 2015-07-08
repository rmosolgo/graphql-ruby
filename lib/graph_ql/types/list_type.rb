class GraphQL::ListType < GraphQL::ObjectType
  attr_reader :of_type
  def initialize(of_type:)
    @of_type = of_type
  end

  def kind
    GraphQL::TypeKinds::LIST
  end
end
