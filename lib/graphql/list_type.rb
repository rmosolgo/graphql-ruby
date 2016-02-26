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
    ensure_array(value).all?{ |item| of_type.valid_input?(item) }
  end

  def validate_non_null_input(value)
    result = GraphQL::Query::InputValidationResult.new

    ensure_array(value).each_with_index do |item, index|
      item_result = of_type.validate_input(item)
      result.merge_result!(index, item_result) unless item_result.is_valid?
    end
    
    result
  end


  def coerce_non_null_input(value)
    ensure_array(value).map{ |item| of_type.coerce_input(item) }
  end


  private

  def ensure_array(value)
    value.is_a?(Array) ? value : [value]
  end
end
