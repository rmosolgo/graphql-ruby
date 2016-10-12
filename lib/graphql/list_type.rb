module GraphQL
  # A list type modifies another type.
  #
  # List types can be created with the type helper (`types[InnerType]`)
  # or {BaseType#to_list_type} (`InnerType.to_list_type`)
  #
  # For return types, it says that the returned value will be a list of the modified.
  #
  # @example A field which returns a list of items
  #   field :items, types[ItemType]
  #   # or
  #   field :items, ItemType.to_list_type
  #
  # For input types, it says that the incoming value will be a list of the modified type.
  #
  # @example A field which accepts a list of strings
  #   field :newNames do
  #     # ...
  #     argument :values, types[types.String]
  #     # or
  #     argument :values, types.String.to_list_type
  #   end
  #
  # Given a list type, you can always get the underlying type with {#unwrap}.
  #
  class ListType < GraphQL::BaseType
    include GraphQL::BaseType::ModifiesAnotherType
    attr_reader :of_type, :name
    ### Ruby 1.9.3 unofficial support
    # def initialize(of_type:)
    def initialize(options = {})
      of_type = options[:of_type]

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
      ensure_array(value).map { |item| of_type.coerce_input(item) }
    end

    def coerce_result(value)
      ensure_array(value).map { |item| item.nil? ? nil : of_type.coerce_result(item) }
    end

    private

    def ensure_array(value)
      value.is_a?(Array) ? value : [value]
    end
  end
end
