# frozen_string_literal: true

module GraphQL
  class Dataloader
    # The default implementation of dataloading -- all no-ops.
    #
    # The Dataloader interface isn't public, but it enables
    # simple internal code while adding the option to add Dataloader.
    class NullDataloader < Dataloader
      # These are all no-ops because code was
      # executed synchronously.

      def initialize(*)
        # TODO unify the initialization lazies_at_depth
        @lazies_at_depth ||= Hash.new { |h, k| h[k] = [] }
        @steps_to_rerun_after_lazy = []
        @queue = []
      end

      def run
        puts "#{self.class}#run ~~~ @q:#{@queue.size} @lad:#{@lazies_at_depth.size} / @stral:#{@steps_to_rerun_after_lazy.size}"
        while @queue.any?
          puts "#{self.class}#run 111 @q:#{@queue.size} @lad:#{@lazies_at_depth.size} / @stral:#{@steps_to_rerun_after_lazy.size}"
          while (step = @queue.shift)
            step.call
          end

          puts "#{self.class}#run 222 @q:#{@queue.size} @lad:#{@lazies_at_depth.size} / @stral:#{@steps_to_rerun_after_lazy.size}"

          while @lazies_at_depth.any?
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

          puts "#{self.class}#run 333 @q:#{@queue.size} @lad:#{@lazies_at_depth.size} / @stral:#{@steps_to_rerun_after_lazy.size}"

          if @steps_to_rerun_after_lazy.any?
            @steps_to_rerun_after_lazy.each(&:call)
            @steps_to_rerun_after_lazy.clear
          end
        end
      end

      def run_isolated
        prev_queue = @queue
        prev_stral = @steps_to_rerun_after_lazy
        prev_lad = @lazies_at_depth
        @steps_to_rerun_after_lazy = []
        @queue = []
        @lazies_at_depth = @lazies_at_depth.dup.clear
        res = nil
        append_job {
          res = yield
        }
        run
        res
      ensure
        @queue = prev_queue
        @steps_to_rerun_after_lazy = prev_stral
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
    end
  end
end
