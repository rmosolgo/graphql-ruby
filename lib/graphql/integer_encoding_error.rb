# frozen_string_literal: true
module GraphQL
  # This error is raised when `Types::Int` is asked to return a value outside of 32-bit integer range.
  #
  # For values outside that range, consider:
  #
  # - `ID` for database primary keys or other identifiers
  # - `GraphQL::Types::BigInt` for really big integer values
  #
  # See [GraphQL::Types::Int](rdoc-ref:GraphQL::Types::Int) which raises this error
  class IntegerEncodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be encoded
    attr_reader :integer_value

    # **Returns**
    #
    # - `GraphQL::Schema::Field` — The field that returned a too-big integer
    #
    # :call-seq:
    #   field -> GraphQL::Schema::Field
    attr_reader :field

    # **Returns**
    #
    # - `Array<String, Integer>` — Where the field appeared in the GraphQL response
    #
    # :call-seq:
    #   path -> Array[String | Integer]
    attr_reader :path

    def initialize(value, context:)
      @integer_value = value
      @field = context[:current_field]
      @path = context[:current_path]
      message = "Integer out of bounds: #{value}".dup
      if @path
        message << " @ #{@path.join(".")}"
      end
      if @field
        message << " (#{@field.path})"
      end
      message << ". Consider using ID or GraphQL::Types::BigInt instead."
      super(message)
    end
  end
end
