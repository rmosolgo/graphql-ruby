# frozen_string_literal: true
require "graphql/tracing/active_support_notifications_tracing"
module GraphQL
  # Library entry point for performance metric reporting.
  #
  # @example Sending custom events
  #   GraphQL::Tracing.trace("my_custom_event", { ... }) do
  #     # do stuff ...
  #   end
  #
  # Events:
  #
  # Key | Metadata
  # ----|---------
  # lex | `{ query_string: String }`
  # parse | `{ query_string: String }`
  # validate | `{ query: GraphQL::Query, validate: Boolean }`
  # analyze.multiplex |  `{ multiplex: GraphQL::Execution::Multiplex }`
  # analyze.query | `{ query: GraphQL::Query }`
  # execute.eager | `{ query: GraphQL::Query }`
  # execute.lazy | `{ query: GraphQL::Query?, queries: Array<GraphQL::Query>? }`
  # execute.field | `{ context: GraphQL::Query::Context::FieldResolutionContext }`
  # execute.field.lazy | `{ context: GraphQL::Query::Context::FieldResolutionContext }`
  #
  module Tracing
    class << self
      # Override this method to do stuff
      # @param key [String] The name of the event in GraphQL internals
      # @param metadata [Hash] Event-related metadata (can be anything)
      # @return [Object] Must return the value of the block
      def trace(key, metadata)
        if @tracer
          @tracer.trace(key, metadata) { yield }
        else
          yield
        end
      end

      # Install a tracer to receive events.
      # @param tracer [<#trace(key, metadata)>]
      # @return [void]
      def install(tracer)
        @tracer = tracer
      end

      def tracer
        @tracer
      end
    end
  end
end

if defined?(ActiveSupport::Notifications)
  GraphQL::Tracing.install(GraphQL::Tracing::ActiveSupportNotificationsTracing)
end
