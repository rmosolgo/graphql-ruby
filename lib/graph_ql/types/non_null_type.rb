# A non-null type wraps another type.
#
# See {TypeKind#unwrap} for accessing the modified type
class GraphQL::NonNullType < GraphQL::ObjectType
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
end
