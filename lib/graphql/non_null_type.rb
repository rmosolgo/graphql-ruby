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
  # (If the application fails to return a value, {InvalidNullError} will be raised.)
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

    attr_reader :of_type
    ### Ruby 1.9.3 unofficial support
    # def initialize(of_type:)
    def initialize(options = {})
      of_type = options[:of_type]

      @of_type = of_type
    end

    def name
      "Non-Null"
    end

    def valid_input?(value)
      validate_input(value).valid?
    end

    def validate_input(value)
      if value.nil?
        result = GraphQL::Query::InputValidationResult.new
        result.add_problem("Expected value to not be null")
        result
      else
        of_type.validate_input(value)
      end
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
end
