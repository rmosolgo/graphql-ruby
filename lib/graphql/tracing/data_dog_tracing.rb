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
        pin = Datadog::Pin.get_from(self)
        unless pin
          pin = Datadog::Pin.new('graphql-ruby')
          pin.onto(self)
        end
        pin.tracer.trace(platform_key) do |span|
          span.service = pin.service
          if data[:query]
            span.set_tag(:selected_operation_name, data[:query].selected_operation_name)
            span.set_tag(:selected_operation_type, data[:query].selected_operation.operation_type)
            span.set_tag(:query_string, data[:query].query_string)
            span.set_tag(:variables, data[:query].variables.to_h)
          end
          yield
        end
      end

      def platform_field_key(type, field)
        "#{type.name}.#{field.name}"
      end
    end
  end
end
