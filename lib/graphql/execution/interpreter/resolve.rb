# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      module Resolve
        # Continue field results in `results` until there's nothing else to continue.
        # @return [void]
        def self.resolve_all(results)
          while results.any?
            results = resolve(results)
          end
        end

        # After getting `results` back from an interpreter evaluation,
        # continue it until you get a response-ready Ruby value.
        #
        # `results` is one level of _depth_ of a query or multiplex.
        #
        # Resolve all lazy values in that depth before moving on
        # to the next level.
        #
        # It's assumed that the lazies will
        # return {Lazy} instances if there's more work to be done,
        # or return {Hash}/{Array} if the query should be continued.
        #
        # @param results [Array]
        # @return [Array] Same size, filled with finished values
        def self.resolve(results)
          next_results = []

          # Work through the queue until it's empty
          while results.size > 0
            result_value = results.shift

            if result_value.is_a?(Lazy)
              result_value = result_value.value
            end

            if result_value.is_a?(Lazy)
              # Since this field returned another lazy,
              # add it to the same queue
              results << result_value
            elsif result_value.is_a?(Hash)
              # This is part of the next level, add it
              next_results.concat(result_value.values)
            elsif result_value.is_a?(Array)
              # This is part of the next level, add it
              next_results.concat(result_value)
            end
          end

          next_results
        end
      end
    end
  end
end
