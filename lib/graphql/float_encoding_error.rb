# frozen_string_literal: true
module GraphQL
  # This error is raised when `Types::Float` is asked to return a non-finite value.
  class FloatEncodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be encoded
    attr_reader :float_value

    # @return [GraphQL::Schema::Field] The field that returned a non-finite float
    attr_reader :field

    # @return [Array<String, Integer>] Where the field appeared in the GraphQL response
    attr_reader :path

    def initialize(value, context:)
      @float_value = value
      @field = context[:current_field]
      @path = context[:current_path]
      message = "Float is not finite: #{value.inspect}".dup
      if @path
        message << " @ #{@path.join(".")}"
      end
      if @field
        message << " (#{@field.path})"
      end
      super("#{message}.")
    end
  end
end
