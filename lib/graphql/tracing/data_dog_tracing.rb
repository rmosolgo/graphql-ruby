# frozen_string_literal: true

module GraphQL
  module Tracing
    class DataDogTracing < PlatformTracing
      self.platform_keys = {
        'lex' => 'graphql.lex',
        'parse' => 'graphql.parse',
        'validate' => 'graphql.validate',
        'analyze_multiplex' => 'graphql.analyze_multiplex',
        'analyze_query' => 'graphql.analyze',
        'execute_multiplex' => 'graphql.execute_multiplex',
        'execute_query' => 'graphql.execute',
        'execute_query_lazy' => 'graphql.execute_lazy'
      }

      def platform_trace(platform_key, key, data)
        case key
        when 'lex'
          tracer.trace('graphql.lex', resource: data[:query_string], service: options[:service], type: 'graphql') do |span|
            prepare_span(key, data, span)
            yield
          end

        when 'parse'
          tracer.trace('graphql.parse', resource: data[:query_string], service: options[:service], type: 'graphql') do |span|
            span.set_tag('graphql.source', data[:query_string])
            prepare_span(key, data, span)
            yield
          end

        when 'validate'
          tracer.trace('graphql.validate', resource: data[:query].selected_operation_name, service: options[:service], type: 'graphql') do |span|
            span.set_tag('graphql.source', data[:query].query_string)
            prepare_span(key, data, span)
            yield
          end

        when 'analyze_multiplex'
          operations = data[:multiplex].queries.map(&:selected_operation_name).compact.join(', ')
          resource = if operations.empty?
            first_query = data[:multiplex].queries.first
            fallback_transaction_name(first_query && first_query.context)
          else
            operations
          end
          tracer.trace('graphql.analyze_multiplex', resource: resource, service: options[:service], type: 'graphql') do |span|
            prepare_span(key, data, span)
            yield
          end

        when 'analyze_query'
          tracer.trace('graphql.analyze', resource: data[:query].query_string, service: options[:service], type: 'graphql') do |span|
            prepare_span('analyze', data, span)
            yield
          end

        when 'execute_multiplex'
          operations = data[:multiplex].queries.map(&:selected_operation_name).join(', ')
          resource = if operations.empty?
            first_query = data[:multiplex].queries.first
            fallback_transaction_name(first_query && first_query.context)
          else
            operations
          end
          tracer.trace('graphql.execute_multiplex', resource: resource, service: options[:service], type: 'graphql') do |span|
            span.set_tag('graphql.source', "Multiplex[#{data[:multiplex].queries.map(&:query_string).compact.join(', ')}]")
            prepare_span(key, data, span)
            yield
          end

        when 'execute_query'
          tracer.trace('graphql.execute', resource: data[:query].selected_operation_name, service: options[:service], type: 'graphql') do |span|
            span.set_tag('graphql.source', data[:query].query_string)
            span.set_tag('graphql.operation.type', data[:query].selected_operation.operation_type)
            span.set_tag('graphql.operation.name', data[:query].selected_operation_name) if data[:query].selected_operation_name
            data[:query].provided_variables.each do |key, value|
              span.set_tag("graphql.variables.#{key}", value)
            end
            prepare_span('execute', data, span)
            yield
          end

        when 'execute_query_lazy'
          resource = if data[:query]
            data[:query].selected_operation_name
          else
            operations = data[:multiplex] && data[:multiplex].queries.map(&:selected_operation_name).join(', ')
            if operations.nil?
              nil
            elsif operations.empty?
              first_query = data[:multiplex].queries.first
              fallback_transaction_name(first_query && first_query.context)
            else
              operations
            end
          end
          tracer.trace('graphql.execute_lazy', resource: resource, service: options[:service], type: 'graphql') do |span|
            prepare_span('execute_lazy', data, span)
            yield
          end

        when 'execute_field'
          execute_field_span('resolve', platform_key, data) do
            yield
          end

        when 'execute_field_lazy'
          execute_field_span('resolve_lazy', platform_key, data) do
            yield
          end

        when 'authorized'
          tracer.trace('graphql.authorized', resource: platform_key, service: options[:service], type: 'graphql') do |span|
            prepare_span(key, data, span)
            yield
          end

        when 'authorized_lazy'
          tracer.trace('graphql.authorized_lazy', resource: platform_key, service: options[:service], type: 'graphql') do |span|
            prepare_span(key, data, span)
            yield
          end

        when 'resolve_type'
          tracer.trace('graphql.resolve_type', resource: platform_key, service: options[:service], type: 'graphql') do |span|
            prepare_span(key, data, span)
            yield
          end

        when 'resolve_type_lazy'
          tracer.trace('graphql.resolve_type_lazy', resource: platform_key, service: options[:service], type: 'graphql') do |span|
            prepare_span(key, data, span)
            yield
          end
        end
      end

      def execute_field_span(span_key, platform_key, data)
        tracer.trace("graphql.#{span_key}", resource: platform_key, service: options[:service], type: 'graphql') do |span|
          data[:query].provided_variables.each do |key, value|
            span.set_tag("graphql.variables.#{key}", value)
          end
          prepare_span_data =
            {
              query: data[:query],
              field: data[:field],
              ast_node: data[:ast_node],
              arguments: data[:arguments],
              object: data[:object],
              owner: data[:owner],
              path: data[:path]
            }
          prepare_span(span_key, prepare_span_data, span)
          yield
        end
      end

      # Implement this method in a subclass to apply custom tags to datadog spans
      # @param key [String] The event being traced
      # @param data [Hash] The runtime data for this event (@see GraphQL::Tracing for keys for each event)
      # @param span [Datadog::Tracing::SpanOperation] The datadog span for this event
      def prepare_span(key, data, span)
      end

      def tracer
        default_tracer = defined?(Datadog::Tracing) ? Datadog::Tracing : Datadog.tracer

        # [Deprecated] options[:tracer] will be removed in the future
        options.fetch(:tracer, default_tracer)
      end

      def analytics_enabled?
        # [Deprecated] options[:analytics_enabled] will be removed in the future
        options.fetch(:analytics_enabled, false)
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
