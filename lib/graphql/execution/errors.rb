# frozen_string_literal: true

module GraphQL
  module Execution
    # A plugin that wraps query execution with error handling.
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
        schema.error_handler = self.new(schema)
      end

      def initialize(schema)
        @schema = schema
      end

      class NullErrorHandler
        def self.with_error_handling(_ctx)
          yield
        end
      end

      # Call the given block with the schema's configured error handlers.
      #
      # If the block returns a lazy value, it's not wrapped with error handling. That area will have to be wrapped itself.
      #
      # @param ctx [GraphQL::Query::Context]
      # @return [Object] Either the result of the given block, or some object to replace the result, in case of error handling.
      def with_error_handling(ctx)
        yield
      rescue StandardError => err
        rescues = ctx.schema.rescues
        _err_class, handler = rescues.find { |err_class, handler| err.is_a?(err_class) }
        if handler
          runtime_info = ctx.namespace(:interpreter) || {}
          obj = runtime_info[:current_object]
          args = runtime_info[:current_arguments]
          field = runtime_info[:current_field]
          if obj.is_a?(GraphQL::Schema::Object)
            obj = obj.object
          end
          handler.call(err, obj, args, ctx, field)
        else
          raise err
        end
      end
    end
  end
end
