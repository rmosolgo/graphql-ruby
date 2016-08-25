module GraphQL
  # Raised automatically when a field's resolve function returns `nil`
  # for a non-null field.
  class InvalidNullError < GraphQL::Error
    def initialize(field_name, value)
      @field_name = field_name
      @value = value
      super("Cannot return null for non-nullable field #{@field_name}")
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
