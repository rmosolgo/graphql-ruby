# frozen_string_literal: true

module GraphQL
  module Tracing
    class SentryTracing < PlatformTracing

      self.platform_keys = {
        "lex" => "graphql.lex",
        "parse" => "graphql.parse",
        "validate" => "graphql.validate",
        "analyze_query" => "graphql.analyze",
        "analyze_multiplex" => "graphql.analyze_multiplex",
        "execute_multiplex" => "graphql.execute_multiplex",
        "execute_query" => "graphql.execute",
        "execute_query_lazy" => "graphql.execute",
      }

      def platform_trace(platform_key, trace_method, data, &block)
        return yield unless Sentry.initialized?

        Sentry.with_child_span(op: platform_key, start_timestamp: Sentry.utc_now.to_f) do |span|
          result = block.call
          span.finish

          if trace_method == "execute_multiplex" && data.key?(:multiplex)
            operations = data[:multiplex].queries.map{|q| operation_name(q) }.join(", ")
            span.set_description(operations)
          elsif trace_method == "execute_query" && data.key?(:query)
            span.set_description(operation_name(data[:query]))
            span.set_data("graphql.document", data[:query].query_string)
            span.set_data("graphql.operation.name", data[:query].selected_operation_name) if data[:query].selected_operation_name
            span.set_data("graphql.operation.type", data[:query].selected_operation.operation_type)
          end

          result
        end
      end

      def platform_field_key(_type, field)
        "graphql.field.#{field.path}"
      end

      def platform_authorized_key(type)
        "graphql.authorized.#{type.graphql_name}"
      end

      def platform_resolve_type_key(type)
        "graphql.resolve_type.#{type.graphql_name}"
      end

      private

      def operation_name(query)
        selected_op = query.selected_operation
        if selected_op
          [selected_op.operation_type, selected_op.name].compact.join(" ")
        else
          "GraphQL Operation"
        end
      end
    end
  end
end
