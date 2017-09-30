# frozen_string_literal: true

module GraphQL
  module Tracing
    class NewRelicTracing < PlatformTracing
      self.platform_keys = {
        "lex" => "GraphQL/lex",
        "parse" => "GraphQL/parse",
        "validate" => "GraphQL/validate",
        "analyze_query" => "GraphQL/analyze",
        "analyze_multiplex" => "GraphQL/analyze",
        "execute_multiplex" => "GraphQL/execute",
        "execute_query" => "GraphQL/execute",
        "execute_query_lazy" => "GraphQL/execute",
      }

      def platform_trace(platform_key, key, data)
        NewRelic::Agent::MethodTracerHelpers.trace_execution_scoped(platform_key) do
          yield
        end
      end

      def platform_field_key(type, field)
        "GraphQL/#{type.name}/#{field.name}"
      end
    end
  end
end
