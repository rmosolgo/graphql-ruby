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

        INSTRUMENT_OPTS = { scope: true }

        include MonitorTrace::Monitor::GraphQLSuffixNames

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
