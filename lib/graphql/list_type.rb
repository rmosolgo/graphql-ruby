# A list type wraps another type.
#
# Get the underlying type with {#unwrap}
class GraphQL::ListType < GraphQL::BaseType
  include GraphQL::BaseType::ModifiesAnotherType
  attr_reader :of_type, :name
  def initialize(of_type:)
    @name = "List"
    @of_type = of_type
  end

  def kind
    GraphQL::TypeKinds::LIST
  end

  def to_s
    "[#{of_type.to_s}]"
  end
end
