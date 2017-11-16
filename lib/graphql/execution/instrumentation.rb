# frozen_string_literal: true
module GraphQL
  module Execution
    module Instrumentation
      # This function implements the instrumentation policy:
      #
      # - Instrumenters are a stack; the first `before_query` will have the last `after_query`
      # - If a `before_` hook returned without an error, its corresponding `after_` hook will run.
      # - If the `before_` hook did _not_ run, the `after_` hook will not be called.
      #
      # When errors are raised from `after_` hooks:
      #   - Subsequent `after_` hooks _are_ called
      #   - The first raised error is captured; later errors are ignored
      #   - If an error was capture, it's re-raised after all hooks are finished
      #
      # Partial runs of instrumentation are possible:
      # - If a `before_multiplex` hook raises an error, no `before_query` hooks will run
      # - If a `before_query` hook raises an error, subsequent `before_query` hooks will not run (on any query)
      def self.apply_instrumenters(multiplex)
        schema = multiplex.schema
        queries = multiplex.queries
        query_instrumenters = schema.instrumenters[:query]
        multiplex_instrumenters = schema.instrumenters[:multiplex]

        result = nil
        # First, run multiplex instrumentation, then query instrumentation for each query
        call_multiplex_hooks(multiplex_instrumenters, multiplex) do
          each_query_call_hooks(query_instrumenters, queries) do
            # Let them be executed
            result = yield
          end
        end

        result
      end

      def self.each_query_call_hooks(instrumenters, queries, i = 0)
        if i >= queries.length
          yield
        else
          query = queries[i]
          call_query_hooks(instrumenters, query) {
            each_query_call_hooks(instrumenters, queries, i + 1) {
              yield
            }
          }
        end
      end

      def self.call_query_hooks(instrumenters, query, i = 0)
        if i >= instrumenters.length
          yield
        else
          instrumenters[i].before_query(query)
          begin
            call_query_hooks(instrumenters, query, i + 1) {
              yield
            }
          ensure
            instrumenters[i].after_query(query)
          end
        end
      end

      def self.call_multiplex_hooks(instrumenters, multiplex, i = 0)
        if i >= instrumenters.length
          yield
        else
          instrumenters[i].before_multiplex(multiplex)
          begin
            call_multiplex_hooks(instrumenters, multiplex, i + 1) {
              yield
            }
          ensure
            instrumenters[i].after_multiplex(multiplex)
          end
        end
      end
    end
  end
end
