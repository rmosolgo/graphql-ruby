class GraphQL::ListType < GraphQL::ObjectType
  attr_reader :of_type
  def initialize(of_type:)
    @name = "List"
    @of_type = of_type
  end
  def kind
    GraphQL::TypeKinds::LIST
  end

  def to_s
    "<GraphQL::ListType(#{of_type.name})>"
  end
end
