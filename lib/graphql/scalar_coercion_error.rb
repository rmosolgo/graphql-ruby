# frozen_string_literal: true

module GraphQL
  # This error is raised when a scalar type cannot coerce a value to its expected type. It is considered legacy because it's raised as a RuntimeTypeError from `Schema.type_error` when `Schema.spec_compliant_scalar_coercion_errors` is not enabled.
  class ScalarCoercionError < GraphQL::RuntimeTypeError
    # The value which couldn't be coerced
    attr_reader :value

    # @return [GraphQL::Schema::Field] The field that returned a type error
    attr_reader :field

    # @return [Array<String, Integer>] Where the field appeared in the GraphQL response
    attr_reader :path

    def initialize(message, value:, context:)
      @value = value
      @field = context[:current_field]
      @path = context[:current_path]

      super(message)
    end
  end
end
