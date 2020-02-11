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
            cache = platform_key_cache(data.fetch(:query).context)
            platform_key = cache.fetch(field) do
              cache[field] = platform_field_key(data[:owner], field)
            end

            return_type = field.type.unwrap
            trace_field = if return_type.kind.scalar? || return_type.kind.enum?
              (field.trace.nil? && @trace_scalars) || field.trace
            else
              true
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
          cache = platform_key_cache(data.fetch(:context))
          type = data.fetch(:type)
          platform_key = cache.fetch(type) do
            cache[type] = platform_authorized_key(type)
          end
          platform_trace(platform_key, key, data) do
            yield
          end
        when "resolve_type", "resolve_type_lazy"
          cache = platform_key_cache(data.fetch(:context))
          type = data.fetch(:type)
          platform_key = cache.fetch(type) do
            cache[type] = platform_resolve_type_key(type)
          end
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
        tracer = self.new(options)
        schema_defn.instrument(:field, tracer)
        schema_defn.tracer(tracer)
      end

      private
      attr_reader :options

      def platform_key_cache(ctx)
        ctx.namespace(self.class)[:platform_key_cache] ||= {}
      end
    end
  end
end
