# frozen_string_literal: true
require "graphql/tracing/active_support_notifications_tracing"
module GraphQL
  # Library entry point for performance metric reporting.
  #
  # {ActiveSupportNotificationsTracing} is imported by default
  # when `ActiveSupport::Notifications` is found.
  #
  # You can remove it with `GraphQL::Tracing.uninstall(GraphQL::Tracing::ActiveSupportNotificationsTracing)`.
  #
  # __Warning:__ Installing/uninstalling tracers is not thread-safe. Do it during application boot only.
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
  # analyze_multiplex |  `{ multiplex: GraphQL::Execution::Multiplex }`
  # analyze_query | `{ query: GraphQL::Query }`
  # execute_multiplex | `{ query: GraphQL::Execution::Multiplex }`
  # execute_query | `{ query: GraphQL::Query }`
  # execute_query_lazy | `{ query: GraphQL::Query?, queries: Array<GraphQL::Query>? }`
  # execute_field | `{ context: GraphQL::Query::Context::FieldResolutionContext }`
  # execute_field_lazy | `{ context: GraphQL::Query::Context::FieldResolutionContext }`
  #
  module Tracing
    class << self
      # Override this method to do stuff
      # @param key [String] The name of the event in GraphQL internals
      # @param metadata [Hash] Event-related metadata (can be anything)
      # @return [Object] Must return the value of the block
      def trace(key, metadata)
        call_tracers(0, key, metadata) { yield }
      end

      # Install a tracer to receive events.
      # @param tracer [<#trace(key, metadata)>]
      # @return [void]
      def install(tracer)
        if !tracers.include?(tracer)
          @tracers << tracer
        end
      end

      def uninstall(tracer)
        @tracers.delete(tracer)
      end

      def tracers
        @tracers ||= []
      end

      private

      # If there's a tracer at `idx`, call it and then increment `idx`.
      # Otherwise, yield.
      #
      # @param idx [Integer] Which tracer to call
      # @param key [String] The current event name
      # @param metadata [Object] The current event object
      # @return Whatever the block returns
      def call_tracers(idx, key, metadata)
        if idx == @tracers.length
          yield
        else
          @tracers[idx].trace(key, metadata) { call_tracers(idx + 1, key, metadata) { yield } }
        end
      end
    end
    # Initialize the array
    tracers
  end
end
