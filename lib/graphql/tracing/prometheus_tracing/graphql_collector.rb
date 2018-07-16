# frozen_string_literal: true

module GraphQL
  module Tracing
    class PrometheusTracing < PlatformTracing
      class GraphQLCollector < ::PrometheusExporter::Server::TypeCollector
        def initialize
          @graphql_gauge = PrometheusExporter::Metric::Summary.new(
            'graphql_duration_seconds',
            'Time spent in GraphQL operations, in seconds'
          )
        end

        def type
          'graphql'
        end

        def collect(object)
          labels = { key: object['key'], platform_key: object['platform_key'] }
          @graphql_gauge.observe object['duration'], labels
        end

        def metrics
          [@graphql_gauge]
        end
      end
    end
  end
end
