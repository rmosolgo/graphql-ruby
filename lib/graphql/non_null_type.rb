module GraphQL
  # A non-null type wraps another type.
  #
  # Get the underlying type with {#unwrap}
  class NonNullType < GraphQL::BaseType
    include GraphQL::BaseType::ModifiesAnotherType

    attr_reader :of_type
    def initialize(of_type:)
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

    def kind
      GraphQL::TypeKinds::NON_NULL
    end

    def to_s
      "#{of_type.to_s}!"
    end
  end
end
