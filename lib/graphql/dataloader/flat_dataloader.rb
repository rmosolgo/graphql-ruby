# frozen_string_literal: true
module GraphQL
  class Dataloader
    class FlatDataloader < Dataloader
      def initialize(*)
        # TODO unify the initialization lazies_at_depth
        @lazies_at_depth ||= Hash.new { |h, k| h[k] = [] }
        @queue = []
      end

      def run(trace_query_lazy: nil)
        while !@queue.empty?
          run_pending_steps
          with_trace_query_lazy(trace_query_lazy) do
            while @lazies_at_depth&.any?
              run_next_pending_lazies
              run_pending_steps
            end
          end
        end
      end

      def run_isolated
        prev_queue = @queue
        prev_lad = @lazies_at_depth
        @queue = []
        @lazies_at_depth = @lazies_at_depth.dup&.clear
        res = nil
        append_job {
          res = yield
        }
        run
        res
      ensure
        @queue = prev_queue
        @lazies_at_depth = prev_lad
      end

      def clear_cache; end

      def yield(_source)
        raise GraphQL::Error, "GraphQL::Dataloader is not running -- add `use GraphQL::Dataloader` to your schema to use Dataloader sources."
      end

      def append_job(callable = nil, &block)
        @queue << (callable || block)
        nil
      end

      def with(*)
        raise GraphQL::Error, "GraphQL::Dataloader is not running -- add `use GraphQL::Dataloader` to your schema to use Dataloader sources."
      end

      private

      def run_next_pending_lazies
        smallest_depth = nil
        @lazies_at_depth.each_key do |depth_key|
          smallest_depth ||= depth_key
          if depth_key < smallest_depth
            smallest_depth = depth_key
          end
        end

        if smallest_depth
          lazies = @lazies_at_depth.delete(smallest_depth)
          lazies.each(&:value) # resolve these Lazy instances
        end
      end

      def run_pending_steps
        while (step = @queue.shift)
          step.call
        end
      end
    end
  end
end
