# frozen_string_literal: true
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
    attr_reader :of_type
    def initialize(of_type:)
      super()
      @of_type = of_type
    end

    def kind
      GraphQL::TypeKinds::LIST
    end

    def to_s
      "[#{of_type.to_s}]"
    end
    alias_method :inspect, :to_s
    alias :to_type_signature :to_s

    def coerce_result(value, ctx = nil)
      if ctx.nil?
        warn_deprecated_coerce("coerce_isolated_result")
        ctx = GraphQL::Query::NullContext
      end
      ensure_array(value).map { |item| item.nil? ? nil : of_type.coerce_result(item, ctx) }
    end

    def list?
      true
    end

    private

    def coerce_non_null_input(value, ctx)
      ensure_array(value).map { |item| of_type.coerce_input(item, ctx) }
    end

    def validate_non_null_input(value, ctx)
      result = GraphQL::Query::InputValidationResult.new

      ensure_array(value).each_with_index do |item, index|
        item_result = of_type.validate_input(item, ctx)
        if !item_result.valid?
          result.merge_result!(index, item_result)
        end
      end

      result
    end

    def ensure_array(value)
      value.is_a?(Array) ? value : [value]
    end
  end
end
