# A list type wraps another type.
#
# See {TypeKind#unwrap} for accessing the modified type
class GraphQL::ListType < GraphQL::BaseType
  attr_reader :of_type, :name
  def initialize(of_type:)
    @name = "List"
    @of_type = of_type
  end

  def kind
    GraphQL::TypeKinds::LIST
  end
end
