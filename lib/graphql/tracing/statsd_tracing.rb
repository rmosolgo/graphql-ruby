# frozen_string_literal: true

module GraphQL
  module Tracing
    class StatsdTracing < PlatformTracing
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

      # See https://github.com/etsy/statsd/blob/master/docs/metric_types.md
      # for a reference on statsd terminology.

      def initialize(statsd:)
        @platform_keys = self.class.platform_keys
        @statsd = statsd
      end

      def platform_trace(platform_key, key, data)
        result = @statsd.time(platform_key) do
          yield
        end

        if key == 'execute_query'
          query_name = data[:query].selected_operation_name || '<anonymous query>'

          # Count with 1 actually means increase count with 1
          @statsd.count(query_name, 1)
        end

        result
      end

      def platform_field_key(type, field)
        "#{type.name}.#{field.name}"
      end
    end
  end
end
