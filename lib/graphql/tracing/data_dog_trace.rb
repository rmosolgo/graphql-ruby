# frozen_string_literal: true

module GraphQL
  module Tracing
    module DataDogTrace
      # @param analytics_enabled [Boolean] Deprecated
      # @param analytics_sample_rate [Float] Deprecated
      def initialize(tracer: nil, analytics_enabled: false, analytics_sample_rate: 1.0, service: "ruby-graphql", **rest)
        if tracer.nil?
          tracer = defined?(Datadog::Tracing) ? Datadog::Tracing : Datadog.tracer
        end
        @tracer = tracer

        analytics_available = defined?(Datadog::Contrib::Analytics) \
            && Datadog::Contrib::Analytics.respond_to?(:enabled?) \
            && Datadog::Contrib::Analytics.respond_to?(:set_sample_rate)

        @analytics_enabled = analytics_available && Datadog::Contrib::Analytics.enabled?(analytics_enabled)
        @analytics_sample_rate = analytics_sample_rate
        @service_name = service
        super
      end

      {
        'lex' => 'lex.graphql',
        'parse' => 'parse.graphql',
        'validate' => 'validate.graphql',
        'analyze_query' => 'analyze.graphql',
        'analyze_multiplex' => 'analyze.graphql',
        'execute_multiplex' => 'execute.graphql',
        'execute_query' => 'execute.graphql',
        'execute_query_lazy' => 'execute.graphql',
      }.each do |trace_method, trace_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**data)
            @tracer.trace("#{trace_key}", service: @service_name) do |span|
              span.span_type = 'custom'
              if defined?(Datadog::Tracing::Metadata::Ext) # Introduced in ddtrace 1.0
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, 'graphql')
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, '#{trace_method}')
              end

              #{
                if trace_method == 'execute_multiplex'
                  <<-RUBY
                  operations = data[:multiplex].queries.map(&:selected_operation_name).join(', ')

                  resource = if operations.empty?
                    first_query = data[:multiplex].queries.first
                    fallback_transaction_name(first_query && first_query.context)
                  else
                    operations
                  end
                  span.resource = resource if resource

                  # For top span of query, set the analytics sample rate tag, if available.
                  if @analytics_enabled
                    Datadog::Contrib::Analytics.set_sample_rate(span, @analytics_sample_rate)
                  end
                  RUBY
                elsif trace_method == 'execute_query'
                  <<-RUBY
                  span.set_tag(:selected_operation_name, data[:query].selected_operation_name)
                  span.set_tag(:selected_operation_type, data[:query].selected_operation.operation_type)
                  span.set_tag(:query_string, data[:query].query_string)
                  RUBY
                end
              }
              prepare_span("#{trace_method.sub("platform_", "")}", data, span)
              super
            end
          end
        RUBY
      end

      def platform_execute_field(platform_key, data, span_key = "execute_field")
        @tracer.trace(platform_key, service: @service_name) do |span|
          span.span_type = 'custom'
          if defined?(Datadog::Tracing::Metadata::Ext) # Introduced in ddtrace 1.0
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, 'graphql')
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, span_key)
          end
          prepare_span(span_key, data, span)
          yield
        end
      end

      def platform_execute_field_lazy(platform_key, data, &block)
        platform_execute_field(platform_key, data, "execute_field_lazy", &block)
      end

      def authorized(object:, type:, query:, span_key: "authorized")
        platform_key = @platform_authorized_key_cache[type]
        @tracer.trace(platform_key, service: @service_name) do |span|
          span.span_type = 'custom'
          if defined?(Datadog::Tracing::Metadata::Ext) # Introduced in ddtrace 1.0
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, 'graphql')
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, span_key)
          end
          prepare_span(span_key, {object: object, type: type, query: query}, span)
          super(query: query, type: type, object: object)
        end
      end

      def authorized_lazy(**kwargs, &block)
        authorized(span_key: "authorized_lazy", **kwargs, &block)
      end

      def resolve_type(object:, type:, query:, span_key: "resolve_type")
        platform_key = @platform_resolve_type_key_cache[type]
        @tracer.trace(platform_key, service: @service_name) do |span|
          span.span_type = 'custom'
          if defined?(Datadog::Tracing::Metadata::Ext) # Introduced in ddtrace 1.0
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, 'graphql')
            span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, span_key)
          end
          prepare_span(span_key, {object: object, type: type, query: query}, span)
          super(query: query, type: type, object: object)
        end
      end

      def resolve_type_lazy(**kwargs, &block)
        resolve_type(span_key: "resolve_type_lazy", **kwargs, &block)
      end

      include PlatformTrace

      # Implement this method in a subclass to apply custom tags to datadog spans
      # @param key [String] The event being traced
      # @param data [Hash] The runtime data for this event (@see GraphQL::Tracing for keys for each event)
      # @param span [Datadog::Tracing::SpanOperation] The datadog span for this event
      def prepare_span(key, data, span)
      end

      def platform_field_key(field)
        field.path
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
