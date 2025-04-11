# frozen_string_literal: true
require "graphql/tracing/monitor_trace"

module GraphQL
  module Tracing
    # A tracer for reporting to DataDog
    # @example Adding this tracer to your schema
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::DataDogTrace
    #   end
    # @example Skipping `resolve_type` and `authorized` events
    #   trace_with GraphQL::Tracing::DataDogTrace, trace_authorized: false, trace_resolve_type: false
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

              span.set_tag("selected_operation_name", first_query.selected_operation_name)
              span.set_tag("selected_operation_type", first_query.selected_operation&.operation_type)
              span.set_tag("query_string", first_query.query_string)
            end

            if @has_prepare_span
              @trace.prepare_span(keyword, object, span)
            end
            yield
          end
        end

        include MonitorTrace::Monitor::GraphQLSuffixNames
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
