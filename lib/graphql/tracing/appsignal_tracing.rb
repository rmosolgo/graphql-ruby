# frozen_string_literal: true

module GraphQL
  module Tracing
    class AppsignalTracing < PlatformTracing
      self.platform_keys = {
        "lex" => "lex.graphql",
        "parse" => "parse.graphql",
        "validate" => "validate.graphql",
        "analyze_query" => "analyze.graphql",
        "analyze_multiplex" => "analyze.graphql",
        "execute_multiplex" => "execute.graphql",
        "execute_query" => "execute.graphql",
        "execute_query_lazy" => "execute.graphql",
      }

      def platform_trace(platform_key, key, data)
        Appsignal.instrument(platform_key) do
          yield
        end
      end

      def platform_field_key(type, field)
        "#{type.graphql_name}.#{field.graphql_name}.graphql"
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized.graphql"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type.graphql"
      end
    end
  end
end
