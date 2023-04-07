# frozen_string_literal: true

module GraphQL
  module Tracing
    module NewRelicTrace
      include PlatformTrace

      # @param set_transaction_name [Boolean] If true, the GraphQL operation name will be used as the transaction name.
      #   This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing.
      #   It can also be specified per-query with `context[:set_new_relic_transaction_name]`.
      def initialize(set_transaction_name: false, **_rest)
        @set_transaction_name = set_transaction_name
        super
      end

      def execute_query(query:)
        set_this_txn_name =  query.context[:set_new_relic_transaction_name]
        if set_this_txn_name == true || (set_this_txn_name.nil? && @set_transaction_name)
          NewRelic::Agent.set_transaction_name(transaction_name(query))
        end
        NewRelic::Agent::MethodTracerHelpers.trace_execution_scoped("GraphQL/execute") do
          super
        end
      end

      {
        "lex" => "GraphQL/lex",
        "parse" => "GraphQL/parse",
        "validate" => "GraphQL/validate",
        "analyze_query" => "GraphQL/analyze",
        "analyze_multiplex" => "GraphQL/analyze",
        "execute_multiplex" => "GraphQL/execute",
        "execute_query_lazy" => "GraphQL/execute",
      }.each do |trace_method, platform_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**_keys)
            NewRelic::Agent::MethodTracerHelpers.trace_execution_scoped("#{platform_key}") do
              super
            end
          end
        RUBY
      end

      def platform_execute_field(platform_key)
        NewRelic::Agent::MethodTracerHelpers.trace_execution_scoped(platform_key) do
          yield
        end
      end

      def platform_authorized(platform_key)
        NewRelic::Agent::MethodTracerHelpers.trace_execution_scoped(platform_key) do
          yield
        end
      end

      def platform_resolve_type(platform_key)
        NewRelic::Agent::MethodTracerHelpers.trace_execution_scoped(platform_key) do
          yield
        end
      end

      def platform_field_key(field)
        "GraphQL/#{field.owner.graphql_name}/#{field.graphql_name}"
      end

      def platform_authorized_key(type)
        "GraphQL/Authorize/#{type.graphql_name}"
      end

      def platform_resolve_type_key(type)
        "GraphQL/ResolveType/#{type.graphql_name}"
      end
    end
  end
end
