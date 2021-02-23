# frozen_string_literal: true

module GraphQL
  module Tracing
    # Each platform provides:
    # - `.platform_keys`
    # - `#platform_trace`
    # - `#platform_field_key(type, field)`
    # @api private
    class PlatformTracing
      class << self
        attr_accessor :platform_keys
      end

      def initialize(options = {})
        @options = options
        @platform_keys = self.class.platform_keys
        @trace_scalars = options.fetch(:trace_scalars, false)
      end

      def trace(key, data)
        case key
        when "lex", "parse", "validate", "analyze_query", "analyze_multiplex", "execute_query", "execute_query_lazy", "execute_multiplex"
          platform_key = @platform_keys.fetch(key)
          platform_trace(platform_key, key, data) do
            yield
          end
        when "execute_field", "execute_field_lazy"
          if data[:context]
            field = data[:context].field
            platform_key = field.metadata[:platform_key]
            trace_field = true # implemented with instrumenter
          else
            field = data[:field]
            return_type = field.type.unwrap
            trace_field = if return_type.kind.scalar? || return_type.kind.enum?
              (field.trace.nil? && @trace_scalars) || field.trace
            else
              true
            end

            platform_key = if trace_field
              context = data.fetch(:query).context
              cached_platform_key(context, field) { platform_field_key(data[:owner], field) }
            else
              nil
            end
          end

          if platform_key && trace_field
            platform_trace(platform_key, key, data) do
              yield
            end
          else
            yield
          end
        when "authorized", "authorized_lazy"
          type = data.fetch(:type)
          context = data.fetch(:context)
          platform_key = cached_platform_key(context, type) { platform_authorized_key(type) }
          platform_trace(platform_key, key, data) do
            yield
          end
        when "resolve_type", "resolve_type_lazy"
          type = data.fetch(:type)
          context = data.fetch(:context)
          platform_key = cached_platform_key(context, type) { platform_resolve_type_key(type) }
          platform_trace(platform_key, key, data) do
            yield
          end
        else
          # it's a custom key
          yield
        end
      end

      def instrument(type, field)
        return_type = field.type.unwrap
        case return_type
        when GraphQL::ScalarType, GraphQL::EnumType
          if field.trace || (field.trace.nil? && @trace_scalars)
            trace_field(type, field)
          else
            field
          end
        else
          trace_field(type, field)
        end
      end

      def trace_field(type, field)
        new_f = field.redefine
        new_f.metadata[:platform_key] = platform_field_key(type, field)
        new_f
      end

      def self.use(schema_defn, options = {})
        tracer = self.new(**options)
        if !schema_defn.is_a?(Class)
          schema_defn.instrument(:field, tracer)
        end
        schema_defn.tracer(tracer)
      end

      private

      # Get the transaction name based on the operation type and name
      def transaction_name(query)
        selected_op = query.selected_operation
        if selected_op
          op_type = selected_op.operation_type
          op_name = selected_op.name || "anonymous"
        else
          op_type = "query"
          op_name = "anonymous"
        end
        "GraphQL/#{op_type}.#{op_name}"
      end

      attr_reader :options

      # Different kind of schema objects have different kinds of keys:
      #
      # - Object types: `.authorized`
      # - Union/Interface types: `.resolve_type`
      # - Fields: execution
      #
      # So, they can all share one cache.
      #
      # If the key isn't present, the given block is called and the result is cached for `key`.
      #
      # @return [String]
      def cached_platform_key(ctx, key)
        cache = ctx.namespace(self.class)[:platform_key_cache] ||= {}
        cache.fetch(key) { cache[key] = yield }
      end
    end
  end
end
