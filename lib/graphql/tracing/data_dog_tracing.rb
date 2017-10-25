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
        blacklisted_variables = options.fetch(:blacklisted_variables, [])
        service = options.fetch(:service, 'ruby-graphql')

        pin = Datadog::Pin.get_from(self)
        unless pin
          pin = Datadog::Pin.new(service)
          pin.onto(self)
        end

        pin.tracer.trace(platform_key, service: pin.service) do |span|
          if key == 'execute_multiplex'
            span.resource = data[:multiplex].queries.map(&:selected_operation_name).join(', ')
          end

          if key == 'execute_query'
            span.set_tag(:selected_operation_name, data[:query].selected_operation_name)
            span.set_tag(:selected_operation_type, data[:query].selected_operation.operation_type)
            span.set_tag(:query_string, data[:query].query_string)
            span.set_tag(:variables, scrub_variables(data[:query].variables.to_h), blacklisted_variables)
          end
          yield
        end
      end

      def platform_field_key(type, field)
        "#{type.name}.#{field.name}"
      end

      def scrub_variables(variables, blacklisted_variables)
        Scrubber::Variables.perform(variables, blacklisted_variables)
      end
    end
  end
end
