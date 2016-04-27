module GraphQL
  # A list type wraps another type.
  #
  # Get the underlying type with {#unwrap}
  class ListType < GraphQL::BaseType
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

    def validate_non_null_input(value)
      result = GraphQL::Query::InputValidationResult.new

      ensure_array(value).each_with_index do |item, index|
        item_result = of_type.validate_input(item)
        if !item_result.valid?
          result.merge_result!(index, item_result)
        end
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
end
