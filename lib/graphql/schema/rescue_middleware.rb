# frozen_string_literal: true
module GraphQL
  class Schema
    # - Store a table of errors & handlers
    # - Rescue errors in a middleware chain, then check for a handler
    # - If a handler is found, use it & return a {GraphQL::ExecutionError}
    # - If no handler is found, re-raise the error
    class RescueMiddleware
      # @return [Hash] `{class => proc}` pairs for handling errors
      attr_reader :rescue_table
      def initialize
        @rescue_table = {}
      end

      # @example Rescue from not-found by telling the user
      #   MySchema.rescue_from(ActiveRecord::RecordNotFound) { "An item could not be found" }
      #
      # @param error_classes [Class] one or more classes of errors to rescue from
      # @yield [err] A handler to return a message for these error instances
      # @yieldparam [Exception] an error that was rescued
      # @yieldreturn [String] message to put in GraphQL response
      def rescue_from(*error_classes, &block)
        error_classes.map{ |error_class| rescue_table[error_class] = block }
      end

      # Remove the handler for `error_classs`
      # @param error_class [Class] the error class whose handler should be removed
      def remove_handler(*error_classes)
        error_classes.map{ |error_class| rescue_table.delete(error_class) }
      end

      # Implement the requirement for {GraphQL::Schema::MiddlewareChain}
      def call(*args)
        begin
          yield
        rescue StandardError => err
          attempt_rescue(err)
        end
      end

      private

      def attempt_rescue(err)
        rescue_table.each { |klass, handler|
          if klass.is_a?(Class) && err.is_a?(klass) && handler
            result = handler.call(err)
            case result
            when String
              return GraphQL::ExecutionError.new(result)
            when GraphQL::ExecutionError
              return result
            end
          end
        }

        raise(err)
      end
    end
  end
end
