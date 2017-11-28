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

        # First, run multiplex instrumentation, then query instrumentation for each query
        call_hooks(multiplex_instrumenters, multiplex, :before_multiplex, :after_multiplex) do
          each_query_call_hooks(query_instrumenters, queries) do
            # Let them be executed
            yield
          end
        end
      end

      class << self
        private
        # Call the before_ hooks of each query,
        # Then yield if no errors.
        # `call_hooks` takes care of appropriate cleanup.
        def each_query_call_hooks(instrumenters, queries, i = 0)
          if i >= queries.length
            yield
          else
            query = queries[i]
            call_hooks(instrumenters, query, :before_query, :after_query) {
              each_query_call_hooks(instrumenters, queries, i + 1) {
                yield
              }
            }
          end
        end

        # Call each before hook, and if they all succeed, yield.
        # If they don't all succeed, call after_ for each one that succeeded.
        def call_hooks(instrumenters, object, before_hook_name, after_hook_name, i = 0)
          if i >= instrumenters.length
            # We've reached the end of the instrumenters, so start exiting the call stack.
            # (This will eventually call the originally-passed block.)
            yield
          else
            # Get the next instrumenter and call the before_hook.
            instrumenter = instrumenters[i]
            instrumenter.public_send(before_hook_name, object)
            # At this point, the before_hook did _not_ raise an error.
            # (If it did raise an error, we wouldn't reach this point.)
            # So we should guarantee that we run the after_hook.
            begin
              # Call the next instrumenter on the list,
              # basically passing along the original block
              call_hooks(instrumenters, object, before_hook_name, after_hook_name, i + 1) {
                yield
              }
            ensure
              # Regardless of how the next instrumenter in the list behaves,
              # call the after_hook of this instrumenter
              instrumenter.public_send(after_hook_name, object)
            end
          end
        end
      end
    end
  end
end
