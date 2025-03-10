# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # A tracer for reporting GraphQL-Ruby time to New Relic
    #
    # @example Installing the tracer
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::NewRelicTrace
    #
    #     # Optional, use the operation name to set the new relic transaction name:
    #     # trace_with GraphQL::Tracing::NewRelicTrace, set_transaction_name: true
    #   end
    #
    # @example Installing without trace events for `authorized?` or `resolve_type` calls
    #   trace_with GraphQL::Tracing::NewRelicTrace, trace_authorized: false, trace_resolve_type: false
    module NewRelicTrace
      include NotificationsTrace
      class NewRelicEngine < NotificationsTrace::Engine
        PARSE_NAME = "GraphQL/parse"
        LEX_NAME = "GraphQL/lex"
        VALIDATE_NAME = "GraphQL/validate"
        EXECUTE_NAME = "GraphQL/execute"
        ANALYZE_NAME = "GraphQL/analyze"

        def instrument(keyword, payload, &block)
          if keyword == :execute && payload.queries.size == 1
            query = payload.queries.first
            set_this_txn_name = query.context[:set_new_relic_transaction_name]
            if set_this_txn_name || (set_this_txn_name.nil? && @set_transaction_name)
              NewRelic::Agent.set_transaction_name(transaction_name(query))
            end
          end
          ::NewRelic::Agent::MethodTracerHelpers.trace_execution_scoped(name_for(keyword, payload), &block)
        end

        def platform_source_class_key(source_class)
          "GraphQL/Source/#{source_class.name}"
        end

        def platform_field_key(field)
          "GraphQL/#{field.owner.graphql_name}/#{field.graphql_name}"
        end

        def platform_authorized_key(type)
          "GraphQL/Authorized/#{type.graphql_name}"
        end

        def platform_resolve_type_key(type)
          "GraphQL/ResolveType/#{type.graphql_name}"
        end

        class Event < NotificationsTrace::Engine::Event
          def start
            name = @engine.name_for(keyword, payload)
            @nr_ev = NewRelic::Agent::Tracer.start_transaction_or_segment(partial_name: name, category: :web)
          end

          def finish
            @nr_ev.finish
          end
        end
      end

      # @see NotificationsTrace Parent module documents configuration options
      def initialize(engine: NewRelicEngine, **_rest)
        super
      end
    end
  end
end
