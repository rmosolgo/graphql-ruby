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

  def valid_input?(value)
    !value.nil? && of_type.valid_input?(value)
  end

  def coerce_input(value)
    of_type.coerce_input(value)
  end

  def coerce_result(value)
    of_type.coerce_result(value)
  end

  def kind
    GraphQL::TypeKinds::NON_NULL
  end

  def to_s
    "#{of_type.to_s}!"
  end
end
