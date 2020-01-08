# frozen_string_literal: true

module GraphQL
  module Tracing
    class DataDogTracing < PlatformTracing
      self.platform_keys = {
        'lex' => 'lex.graphql',
        'parse' => 'parse.graphql',
        'validate' => 'validate.graphql',
        'analyze_query' => 'analyze.graphql',
        'analyze_multiplex' => 'analyze.graphql',
        'execute_multiplex' => 'execute.graphql',
        'execute_query' => 'execute.graphql',
        'execute_query_lazy' => 'execute.graphql',
      }

      def platform_trace(platform_key, key, data)
        tracer.trace(platform_key, service: service_name) do |span|
          span.span_type = 'custom'

          if key == 'execute_multiplex'
            operations = data[:multiplex].queries.map(&:selected_operation_name).join(', ')
            span.resource = operations unless operations.empty?

            # For top span of query, set the analytics sample rate tag, if available.
            if analytics_enabled?
              Datadog::Contrib::Analytics.set_sample_rate(span, analytics_sample_rate)
            end
          end

          if key == 'execute_query'
            span.set_tag(:selected_operation_name, data[:query].selected_operation_name)
            span.set_tag(:selected_operation_type, data[:query].selected_operation.operation_type)
            span.set_tag(:query_string, data[:query].query_string)
          end

          yield
        end
      end

      def service_name
        options.fetch(:service, 'ruby-graphql')
      end

      def tracer
        options.fetch(:tracer, Datadog.tracer)
      end

      def analytics_available?
        defined?(Datadog::Contrib::Analytics) \
          && Datadog::Contrib::Analytics.respond_to?(:enabled?) \
          && Datadog::Contrib::Analytics.respond_to?(:set_sample_rate)
      end

      def analytics_enabled?
        analytics_available? && Datadog::Contrib::Analytics.enabled?(options.fetch(:analytics_enabled, false))
      end

      def analytics_sample_rate
        options.fetch(:analytics_sample_rate, 1.0)
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
    end
  end
end
