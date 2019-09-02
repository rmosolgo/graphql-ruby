# frozen_string_literal: true

module GraphQL
  module Execution
    # A tracer that wraps query execution with error handling.
    # Supports class-based schemas and the new {Interpreter} runtime only.
    #
    # @example Handling ActiveRecord::NotFound
    #
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Execution::Errors
    #
    #     rescue_from(ActiveRecord::NotFound) do |err, obj, args, ctx, field|
    #       ErrorTracker.log("Not Found: #{err.message}")
    #       nil
    #     end
    #   end
    #
    class Errors
      def self.use(schema)
        schema_class = schema.is_a?(Class) ? schema : schema.target.class
        schema.tracer(self.new(schema_class))
      end

      def initialize(schema)
        @schema = schema
      end

      def trace(event, data)
        case event
        when "execute_field", "execute_field_lazy"
          with_error_handling(data) { yield }
        else
          yield
        end
      end

      private

      def with_error_handling(trace_data)
        yield
      rescue StandardError => err
        rescues = @schema.rescues
        _err_class, handler = rescues.find { |err_class, handler| err.is_a?(err_class) }
        if handler
          obj = trace_data[:object]
          args = trace_data[:arguments]
          ctx = trace_data[:query].context
          field = trace_data[:field]
          handler.call(err, obj, args, ctx, field)
        else
          raise err
        end
      end
    end
  end
end
