# frozen_string_literal: true
module GraphQL
  class Schema
    # In early GraphQL versions, errors would be "automatically"
    # rescued and replaced with `"Internal error"`. That behavior
    # was undesirable but this middleware is offered for people who
    # want to preserve it.
    #
    # It has a couple of differences from the previous behavior:
    #
    # - Other parts of the query _will_ be run (previously,
    #   execution would stop when the error was raised and the result
    #   would have no `"data"` key at all)
    # - The entry in {Query::Context#errors} is a {GraphQL::ExecutionError}, _not_
    #   the originally-raised error.
    # - The entry in the `"errors"` key includes the location of the field
    #   which raised the errors.
    #
    # @example Use CatchallMiddleware with your schema
    #     # All errors will be suppressed and replaced with "Internal error" messages
    #     MySchema.middleware << GraphQL::Schema::CatchallMiddleware
    #
    module CatchallMiddleware
      MESSAGE = "Internal error"

      # Rescue any error and replace it with a {GraphQL::ExecutionError}
      # whose message is {MESSAGE}
      def self.call(parent_type, parent_object, field_definition, field_args, query_context)
        yield
      rescue StandardError
        GraphQL::ExecutionError.new(MESSAGE)
      end
    end
  end
end
