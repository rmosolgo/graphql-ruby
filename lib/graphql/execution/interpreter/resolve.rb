# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      module Resolve
        # Continue field results in `results` until there's nothing else to continue.
        # @return [void]
        def self.resolve_all(results, dataloader)
          dataloader.append_job { resolve(results, dataloader) }
          nil
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
        # @return [void]
        def self.resolve(results, dataloader)
          # There might be pending jobs here that _will_ write lazies
          # into the result hash. We should run them out, so we
          # can be sure that all lazies will be present in the result hashes.
          # A better implementation would somehow interleave (or unify)
          # these approaches.
          dataloader.run
          next_results = []
          while results.any?
            result_value = results.shift
            if result_value.is_a?(Hash)
              results.concat(result_value.values)
              next
            elsif result_value.is_a?(Array)
              results.concat(result_value)
              next
            elsif result_value.is_a?(Lazy)
              loaded_value = result_value.value
              if loaded_value.is_a?(Lazy)
                # Since this field returned another lazy,
                # add it to the same queue
                results << loaded_value
              elsif loaded_value.is_a?(Hash) || loaded_value.is_a?(Array)
                # Add these values in wholesale --
                # they might be modified by later work in the dataloader.
                next_results << loaded_value
              end
            end
          end

          if next_results.any?
            dataloader.append_job { resolve(next_results, dataloader) }
          end

          nil
        end
      end
    end
  end
end
