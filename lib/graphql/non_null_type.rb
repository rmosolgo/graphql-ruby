# frozen_string_literal: true
module GraphQL
  # A non-null type modifies another type.
  #
  # Non-null types can be created with `!` (`InnerType!`)
  # or {BaseType#to_non_null_type} (`InnerType.to_non_null_type`)
  #
  # For return types, it says that the returned value will _always_ be present.
  #
  # @example A field which _always_ returns an error
  #   field :items, !ItemType
  #   # or
  #   field :items, ItemType.to_non_null_type
  #
  # (If the application fails to return a value, {InvalidNullError} will be passed to {Schema#type_error}.)
  #
  # For input types, it says that the incoming value _must_ be provided by the query.
  #
  # @example A field which _requires_ a string input
  #   field :newNames do
  #     # ...
  #     argument :values, !types.String
  #     # or
  #     argument :values, types.String.to_non_null_type
  #   end
  #
  # (If a value isn't provided, {Query::VariableValidationError} will be raised).
  #
  # Given a non-null type, you can always get the underlying type with {#unwrap}.
  #
  class NonNullType < GraphQL::BaseType
    include GraphQL::BaseType::ModifiesAnotherType
    extend Forwardable

    attr_reader :of_type
    def initialize(of_type:)
      super()
      @of_type = of_type
    end

    def valid_input?(value, ctx)
      validate_input(value, ctx).valid?
    end

    def validate_input(value, ctx)
      if value.nil?
        result = GraphQL::Query::InputValidationResult.new
        result.add_problem("Expected value to not be null")
        result
      else
        of_type.validate_input(value, ctx)
      end
    end

    def_delegators :@of_type, :coerce_input, :coerce_result, :list?

    def kind
      GraphQL::TypeKinds::NON_NULL
    end

    def to_s
      "#{of_type.to_s}!"
    end
    alias_method :inspect, :to_s
    alias :to_type_signature :to_s

    def non_null?
      true
    end
  end
end
