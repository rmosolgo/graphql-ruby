# A non-null type wraps another type.
#
# Get the underlying type with {#unwrap}
class GraphQL::NonNullType < GraphQL::BaseType
  include GraphQL::BaseType::ModifiesAnotherType

  attr_reader :of_type
  def initialize(of_type:)
    @of_type = of_type
  end

  def name
    "Non-Null"
  end

  def coerce(value)
    of_type.coerce(value)
  end

  def kind
    GraphQL::TypeKinds::NON_NULL
  end

  def to_s
    "#{of_type.to_s}!"
  end
end
