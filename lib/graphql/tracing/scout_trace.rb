# frozen_string_literal: true

require "graphql/tracing/monitor_trace"

module GraphQL
  module Tracing
    # A tracer for sending GraphQL-Ruby times to Scout
    #
    # @example Adding this tracer to your schema
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::ScoutTrace
    #   end
    ScoutTrace = MonitorTrace.create_module("scout")
    module ScoutTrace
      class ScoutMonitor < MonitorTrace::Monitor
        def instrument(keyword, object)
          if keyword == :execute
            query = object.queries.first
            set_this_txn_name = query.context[:set_scout_transaction_name]
            if set_this_txn_name == true || (set_this_txn_name.nil? && @set_transaction_name)
              ScoutApm::Transaction.rename(transaction_name(query))
            end
          end

          ScoutApm::Tracer.instrument("GraphQL", name_for(keyword, object), INSTRUMENT_OPTS) do
            yield
          end
        end

        PARSE_NAME = "parse.graphql"
        LEX_NAME = "lex.graphql"
        VALIDATE_NAME = "validate.graphql"
        EXECUTE_NAME = "execute.graphql"
        ANALYZE_NAME = "analyze.graphql"
        INSTRUMENT_OPTS = { scope: true }

        def platform_field_key(field)
          field.path
        end

        def platform_authorized_key(type)
          "#{type.graphql_name}.authorized"
        end

        def platform_resolve_type_key(type)
          "#{type.graphql_name}.resolve_type"
        end

        def platform_source_class_key(source_class)
          "#{source_class.name.gsub("::", "_")}.fetch"
        end

        class Event < MonitorTrace::Monitor::Event
          def start
            layer = ScoutApm::Layer.new("GraphQL", @monitor.name_for(keyword, object))
            layer.subscopable!
            @scout_req = ScoutApm::RequestManager.lookup
            @scout_req.start_layer(layer)
          end

          def finish
            @scout_req.stop_layer
          end
        end
      end
    end
  end
end
