module GraphQL
  # Raised automatically when a field's resolve function returns `nil`
  # or returns a {GraphQL::ExecutionError} for a non-null field.
  #
  # You can handle these errors with {Schema#invalid_null}.
  class InvalidNullError < GraphQL::Error
    # @return [GraphQL::ObjectType] The owner of the field which had an invalid null
    attr_reader :parent_type

    # @return [String] The name of the field which returned `nil` or an {ExecutionError}
    attr_reader :field_name

    def initialize(parent_type, field_name, value)
      @parent_type = parent_type
      @field_name = field_name
      @value = value
      super("Cannot return null for non-nullable field #{@parent_type.name}.#{@field_name}")
    end

    # @return [Hash] An entry for the response's "errors" key
    def to_h
      { "message" => message }
    end

    # @return [Boolean] Whether the null in question was caused by another error
    def parent_error?
      @value.is_a?(GraphQL::ExecutionError)
    end
  end
end
