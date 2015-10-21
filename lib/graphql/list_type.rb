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

  def valid_non_null_input?(value)
    return false unless value.is_a?(Array)
    value.all?{ |item| of_type.valid_input?(item) }
  end

  def coerce_non_null_input(value)
    value.map{ |item| of_type.coerce_input(item) }
  end
end
