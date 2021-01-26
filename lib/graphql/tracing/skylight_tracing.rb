# frozen_string_literal: true

module GraphQL
  module Tracing
    class SkylightTracing < PlatformTracing
      self.platform_keys = {
        "lex" => "graphql.language",
        "parse" => "graphql.language",
        "validate" => "graphql.prepare",
        "analyze_query" => "graphql.prepare",
        "analyze_multiplex" => "graphql.prepare",
        "execute_multiplex" => "graphql.execute",
        "execute_query" => "graphql.execute",
        "execute_query_lazy" => "graphql.execute",
      }

      # @param set_endpoint_name [Boolean] If true, the GraphQL operation name will be used as the endpoint name.
      #   This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing.
      #   It can also be specified per-query with `context[:set_skylight_endpoint_name]`.
      def initialize(options = {})
        GraphQL::Deprecation.warn("GraphQL::Tracing::SkylightTracing is deprecated and will be removed in GraphQL-Ruby 2.0, please enable Skylight's GraphQL probe instead: https://www.skylight.io/support/getting-more-from-skylight#graphql.")
        @set_endpoint_name = options.fetch(:set_endpoint_name, false)
        super
      end

      def platform_trace(platform_key, key, data)
        if key == "execute_query"
          query = data[:query]
          title = query.selected_operation_name || "<anonymous>"
          category = platform_key
          set_endpoint_name_override = query.context[:set_skylight_endpoint_name]
          if set_endpoint_name_override == true || (set_endpoint_name_override.nil? && @set_endpoint_name)
            # Assign the endpoint so that queries will be grouped
            instrumenter = Skylight.instrumenter
            if instrumenter
              current_trace = instrumenter.current_trace
              if current_trace
                op_type = query.selected_operation ? query.selected_operation.operation_type : "query"
                endpoint = "GraphQL/#{op_type}.#{title}"
                current_trace.endpoint = endpoint
              end
            end
          end
        elsif key.start_with?("execute_field")
          title = platform_key
          category = key
        else
          title = key
          category = platform_key
        end

        Skylight.instrument(category: category, title: title) do
          yield
        end
      end

      def platform_field_key(type, field)
        "graphql.#{type.graphql_name}.#{field.graphql_name}"
      end

      def platform_authorized_key(type)
        "graphql.authorized.#{type.graphql_name}"
      end

      def platform_resolve_type_key(type)
        "graphql.resolve_type.#{type.graphql_name}"
      end
    end
  end
end
