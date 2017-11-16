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
        completely_instrumented_queries = 0
        partial_instrumenters = 0
        completed_multiplex_instrumenters = 0

        schema = multiplex.schema
        queries = multiplex.queries
        query_instrumenters = schema.instrumenters[:query]
        multiplex_instrumenters = schema.instrumenters[:multiplex]

        # First, run multiplex instrumentation, then query instrumentation for each query
        multiplex_instrumenters.each { |i|
          i.before_multiplex(multiplex)
          completed_multiplex_instrumenters += 1
        }
        queries.each do |query|
          query_instrumenters.each { |i|
            i.before_query(query)
            partial_instrumenters += 1
          }
          partial_instrumenters = 0
          completely_instrumented_queries += 1
        end

        # Let them be executed
        yield
      ensure
        # Finally, run teardown instrumentation for each query + the multiplex
        # Use `reverse_each` so instrumenters are treated like a stack
        last_complete_query_idx = completely_instrumented_queries - 1
        partial_query_idx = last_complete_query_idx + 1
        # If we get an error in teardown, we hold the _first_ one here.
        # (Later ones are ignored.)
        # This one gets re-raised after calling all after_ hooks.
        raised_teardown_error = nil
        queries.each_with_index do |query, idx|
          if idx <= last_complete_query_idx
            query_instrumenters.reverse_each { |i|
              begin
                i.after_query(query)
              rescue
                # It raised an error, but we promised to call the next one.
                raised_teardown_error ||= $!
              end
            }
          elsif idx == partial_query_idx
            finished_instrumenters = query_instrumenters.first(partial_instrumenters)
            finished_instrumenters.reverse_each { |i|
              begin
                i.after_query(query)
              rescue
                raised_teardown_error ||= $!
              end
            }
          else
            # No instrumenters were run on this query,
            # an error occurred before we reached it.
            next
          end
        end
        teardown_insts = multiplex_instrumenters.first(completed_multiplex_instrumenters)
        teardown_insts.reverse_each { |i|
          begin
            i.after_multiplex(multiplex)
          rescue
            raised_teardown_error ||= $!
          end
        }
        if raised_teardown_error
          raise raised_teardown_error
        end
      end
    end
  end
end
