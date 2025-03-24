# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # A tracer for reporting to DataDog
    # @example Adding this tracer to your schema
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::DataDogTrace
    #   end
    # @example Skipping `resolve_type` and `authorized` events
    #   trace_with GraphQL::Tracing::DataDogTrace, skip_authorized: true, skip_resolve_type: true
    DataDogTrace = MonitorTrace.create_module("datadog")
    module DataDogTrace
      class DatadogMonitor < MonitorTrace::Monitor
        def initialize(set_transaction_name:, service: nil, tracer: nil, **_rest)
          super
          if tracer.nil?
            tracer = defined?(Datadog::Tracing) ? Datadog::Tracing : Datadog.tracer
          end
          @tracer = tracer
          @service_name = service
          @has_prepare_span = @trace.respond_to?(:prepare_span)
        end

        attr_reader :tracer, :service_name

        def instrument(keyword, object)
          trace_key = name_for(keyword, object)
          @tracer.trace(trace_key, service: @service_name, type: 'custom') do |span|
            span.set_tag('component', 'graphql')
            op_name = keyword.respond_to?(:name) ? keyword.name : keyword.to_s
            span.set_tag('operation', op_name)

            if keyword == :execute
              operations = object.queries.map(&:selected_operation_name).join(', ')
              first_query = object.queries.first
              resource = if operations.empty?
                fallback_transaction_name(first_query && first_query.context)
              else
                operations
              end
              span.resource = resource if resource

              span.set_tag(:selected_operation_name, first_query.selected_operation_name)
              span.set_tag(:selected_operation_type, first_query.selected_operation&.operation_type)
              span.set_tag(:query_string, first_query.query_string)
            end

            if @has_prepare_span
              @trace.prepare_span(keyword, object, span)
            end
            yield
          end
        end

        PARSE_NAME = "parse.graphql"
        LEX_NAME = "lex.graphql"
        VALIDATE_NAME = "validate.graphql"
        EXECUTE_NAME = "execute.graphql"
        ANALYZE_NAME = "analyze.graphql"

        private

        def platform_field_key(field)
          field.path
        end

        def platform_authorized_key(type)
          "#{type.graphql_name}.authorized"
        end

        def platform_resolve_type_key(type)
          "#{type.graphql_name}.resolve_type"
        end

        def platform_source_key(source_class)
          "#{source_class.name.gsub("::", "_").name.underscore}.fetch"
        end
        class Event < MonitorTrace::Monitor::Event
          def start
            name = @monitor.name_for(keyword, object)
            @dd_span = @monitor.tracer.trace(name, service: @monitor.service_name, type: 'custom')
          end

          def finish
            @dd_span.finish
          end
        end
      end
    end
  end
end
