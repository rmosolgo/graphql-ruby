# frozen_string_literal: true
module GraphQL
  module Execution
    class Lazy
      class Group
        attr_reader :lazy

        def initialize(maybe_lazies)
          @lazy = Lazy.new(self)
          @maybe_lazies = maybe_lazies
          @waited = false
        end

        def wait
          if !@waited
            @waited = true
            any_lazies = false
            results = @maybe_lazies.map { |maybe_lazy|
              if maybe_lazy.respond_to?(:wait)
                maybe_lazy.wait
                res = maybe_lazy.value
                any_lazies ||= res.is_a?(Lazy)
                res
              else
                maybe_lazy
              end
            }

            if any_lazies
              results = Lazy.all(results)
            end

            lazy.fulfill(results)
          end
        end
      end
    end
  end
end
