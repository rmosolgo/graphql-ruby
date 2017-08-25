# frozen_string_literal: true

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
    # Override this method to do stuff
    # @param key [String] The name of the event in GraphQL internals
    # @param metadata [Hash] Event-related metadata (can be anything)
    # @return [Object] Must return the value of the block
    def self.trace(key, metadata)
      yield
    end
  end
end
