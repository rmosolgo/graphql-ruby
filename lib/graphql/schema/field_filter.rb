# frozen_string_literal: true
module GraphQL
  class Schema
    # Extend this class to make field-level customizations to resolve behavior.
    #
    # When a filter is added to a field with `filter(:my_filter)`, a `MyFilter` instance
    # is created, and its hooks are applied whenever that field is called.
    #
    # The instance is frozen so that instance variables aren't modified during query execution,
    # which could cause all kinds of issues due to race conditions.
    #
    # TODO rename? since it's more than just filter
    class FieldFilter
      # @return [GraphQL::Schema::Field]
      attr_reader :field

      # @return [Object]
      attr_reader :options

      # Called when the filter is mounted with `filter(name, options)`.
      # The instance is frozen to avoid improper use of state during execution.
      # @param field [GraphQL::Schema::Field] The field where this filter was mounted
      # @param options [Object] The second argument to `filter`, or `nil` if nothing was passed.
      def initialize(field:, options:)
        @field = field
        @options = options
        freeze
      end

      # Called before resolving {#field}. It should either:
      # - `yield` values to continue execution; OR
      # - return something else to shortcut field execution.
      # @param object [Object] The object the field is being resolved on
      # @param arguments [Hash] Ruby keyword arguments for resolving this field
      # @param context [Query::Context] the context for this query
      # @yieldparam object [Object] The object to continue resolving the field on
      # @yieldparam arguments [Hash] The keyword arguments to continue resolving with
      # @yieldparam memo [Object] Any filter-specific value which will be passed to {#after_resolve} later
      def before_resolve(object:, arguments:, context:)
        yield(object, arguments, nil)
      end

      # Called after {#field} was resolved, but before the value was added to the GraphQL response.
      # Whatever this hook returns will be used as the return value.
      # @param object [Object] The object the field is being resolved on
      # @param arguments [Hash] Ruby keyword arguments for resolving this field
      # @param context [Query::Context] the context for this query
      # @param value [Object] Whatever the field previously returned
      # @param memo [Object] The third value yielded by {#before_resolve}, or `nil` if there wasn't one
      # @return [Object] The return value for this field.
      def after_resolve(object:, arguments:, context:, value:, memo:)
        value
      end
    end
  end
end
