# frozen_string_literal: true

module GraphQL
  # If a field's resolve function returns a {ExecutionError},
  # the error will be inserted into the response's `"errors"` key
  # and the field will resolve to `nil`.
  class ExecutionErrorsMapper
    attr_accessor :errors

    def initialize(errors = [])
      @errors = errors
    end

    def add(error)
      @errors << error
    end

    def <<(error)
      @errors << error
    end
  end
end
