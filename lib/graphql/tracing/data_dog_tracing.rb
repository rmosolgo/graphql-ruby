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
          if defined?(Datadog::Tracing::Metadata::Ext) # Introduced in ddtrace 1.0
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, 'graphql')
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, key)
          end

          if key == 'execute_multiplex'
            operations = data[:multiplex].queries.map(&:selected_operation_name).join(', ')

            resource = if operations.empty?
              first_query = data[:multiplex].queries.first
              fallback_transaction_name(first_query && first_query.context)
            else
              operations
            end
            span.resource = resource if resource

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

          prepare_span(key, data, span)

          yield
        end
      end

      def service_name
        options.fetch(:service, 'ruby-graphql')
      end

      # Implement this method in a subclass to apply custom tags to datadog spans
      # @param key [String] The event being traced
      # @param data [Hash] The runtime data for this event (@see GraphQL::Tracing for keys for each event)
      # @param span [Datadog::Tracing::SpanOperation] The datadog span for this event
      def prepare_span(key, data, span)
      end

      def tracer
        default_tracer = defined?(Datadog::Tracing) ? Datadog::Tracing : Datadog.tracer

        options.fetch(:tracer, default_tracer)
      end

      def analytics_available?
        defined?(Datadog::Contrib::Analytics) \
          && Datadog::Contrib::Analytics.respond_to?(:enabled?) \
          && Datadog::Contrib::Analytics.respond_to?(:set_sample_rate)
      end

      def analytics_enabled?
        # [Deprecated] options[:analytics_enabled] will be removed in the future
        analytics_available? && Datadog::Contrib::Analytics.enabled?(options.fetch(:analytics_enabled, false))
      end

      def analytics_sample_rate
        # [Deprecated] options[:analytics_sample_rate] will be removed in the future
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
