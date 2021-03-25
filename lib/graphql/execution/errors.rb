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
        definition_line = caller(2, 1).first
        GraphQL::Deprecation.warn("GraphQL::Execution::Errors is now installed by default, remove `use GraphQL::Execution::Errors` from #{definition_line}")
      end

      NEW_HANDLER_HASH = ->(h, k) {
        h[k] = {
          class: k,
          handler: nil,
          subclass_handlers: Hash.new(&NEW_HANDLER_HASH),
         }
      }

      def initialize(schema)
        @schema = schema
        @handlers = {
          class: nil,
          handler: nil,
          subclass_handlers: Hash.new(&NEW_HANDLER_HASH),
        }
      end

      # @api private
      def each_rescue
        handlers = @handlers.values
        while (handler = handlers.shift) do
          yield(handler[:class], handler[:handler])
          handlers.concat(handler[:subclass_handlers].values)
        end
      end

      # Register this handler, updating the
      # internal handler index to maintain least-to-most specific.
      #
      # @param error_class [Class<Exception>]
      # @param error_handler [Proc]
      # @return [void]
      def rescue_from(error_class, error_handler)
        subclasses_handlers = {}
        this_level_subclasses = []
        # During this traversal, do two things:
        # - Identify any already-registered subclasses of this error class
        #   and gather them up to be inserted _under_ this class
        # - Find the point in the index where this handler should be inserted
        #   (That is, _under_ any superclasses, or at top-level, if there are no superclasses registered)
        handlers = @handlers[:subclass_handlers]
        while (handlers) do
          this_level_subclasses.clear
          # First, identify already-loaded handlers that belong
          # _under_ this one. (That is, they're handlers
          # for subclasses of `error_class`.)
          handlers.each do |err_class, handler|
            if err_class < error_class
              subclasses_handlers[err_class] = handler
              this_level_subclasses << err_class
            end
          end
          # Any handlers that we'll be moving, delete them from this point in the index
          this_level_subclasses.each do |err_class|
            handlers.delete(err_class)
          end

          # See if any keys in this hash are superclasses of this new class:
          next_index_point = handlers.find { |err_class, handler| error_class < err_class }
          if next_index_point
            handlers = next_index_point[1][:subclass_handlers]
          else
            # this new handler doesn't belong to any sub-handlers,
            # so insert it in the current set of `handlers`
            break
          end
        end
        # Having found the point at which to insert this handler,
        # register it and merge any subclass handlers back in at this point.
        this_class_handlers = handlers[error_class]
        this_class_handlers[:handler] = error_handler
        this_class_handlers[:subclass_handlers].merge!(subclasses_handlers)
        nil
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
        handler = find_handler_for(err.class)
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

      # @return [Proc, nil] The handler for `error_class`, if one was registered on this schema or inherited
      def find_handler_for(error_class)
        handlers = @handlers[:subclass_handlers]
        handler = nil
        while (handlers) do
          _err_class, next_handler = handlers.find { |err_class, handler| error_class <= err_class }
          if next_handler
            handlers = next_handler[:subclass_handlers]
            handler = next_handler
          else
            # Don't reassign `handler` --
            # let the previous assignment carry over outside this block.
            break
          end
        end

        # check for a handler from a parent class:
        if @schema.superclass.respond_to?(:error_handler) && (parent_errors = @schema.superclass.error_handler)
          parent_handler = parent_errors.find_handler_for(error_class)
        end

        # If the inherited handler is more specific than the one defined here,
        # use it.
        # If it's a tie (or there is no parent handler), use the one defined here.
        # If there's an inherited one, but not one defined here, use the inherited one.
        # Otherwise, there's no handler for this error, return `nil`.
        if parent_handler && handler && parent_handler[:class] < handler[:class]
          parent_handler[:handler]
        elsif handler
          handler[:handler]
        elsif parent_handler
          parent_handler[:handler]
        else
          nil
        end
      end
    end
  end
end
