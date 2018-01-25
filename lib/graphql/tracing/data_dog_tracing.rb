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

      def platform_field_key(type, field)
        "#{type.name}.#{field.name}"
      end
    end
  end
end
