# frozen_string_literal: true

module GraphQL
  module Tracing
    class OpenTelemetryTracing < PlatformTracing
      self.platform_keys = {
        'lex' => 'graphql.lex',
        'parse' => 'graphql.parse',
        'validate' => 'graphql.validate',
        'analyze_query' => 'graphql.analyze_query',
        'analyze_multiplex' => 'graphql.analyze_multiplex',
        'execute_query' => 'graphql.execute_query',
        'execute_query_lazy' => 'graphql.execute_query_lazy',
        'execute_multiplex' => 'graphql.execute_multiplex'
      }

      def platform_trace(platform_key, key, data)
        return yield if platform_key.nil?

        tracer.in_span(platform_key, attributes: attributes_for(key, data)) do |span, _context|
          yield.tap do |response|
            errors = response[:errors]&.compact&.map { |e| e.to_h }&.to_json if key == 'validate'
            unless errors.nil?
              span.add_event(
                'graphql.validation.error',
                attributes: {
                  'message' => errors
                }
              )
            end
          end
        end
      end

      def platform_field_key(type, field)
        "#{type.graphql_name}.#{field.graphql_name}"
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end

      private

      def tracer
        OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance.tracer
      end

      def config
        OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance.config
      end

      def platform_key_enabled?(ctx, key)
        return false unless config[key]

        ns = ctx.namespace(:opentelemetry)
        return true if ns.empty? # restores original behavior so that keys are returned if tracing is not set in context.
        return false unless ns.key?(key) && ns[key]

        return true
      end

      def attributes_for(key, data)
        attributes = {}
        case key
        when 'execute_query'
          attributes['selected_operation_name'] = data[:query].selected_operation_name if data[:query].selected_operation_name
          attributes['selected_operation_type'] = data[:query].selected_operation.operation_type
          attributes['query_string'] = data[:query].query_string
        end
        attributes
      end

      def cached_platform_key(ctx, key, trace_phase)
        cache = ctx.namespace(self.class)[:platform_key_cache] ||= {}

        cache.fetch(key) do
          cache[key] = if trace_phase == :field
            return unless platform_key_enabled?(ctx, :enable_platform_field)

            yield
          elsif trace_phase == :authorized
            return unless platform_key_enabled?(ctx, :enable_platform_authorized)

            yield
          elsif trace_phase == :resolve_type
            return unless platform_key_enabled?(ctx, :enable_platform_resolve_type)

            yield
          else
            raise "Unknown trace phase"
          end
        end
      end
    end
  end
end
