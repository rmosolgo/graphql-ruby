# frozen_string_literal: true

module GraphQL
  class Dataloader
    # GraphQL-Ruby uses this when Dataloader isn't enabled.
    #
    # It runs execution code inline and gathers lazy objects (eg. Promises)
    # and resolves them during {#run}.
    class NullDataloader < Dataloader
      def initialize(*)
        @lazies_at_depth = Hash.new { |h,k| h[k] = [] }
      end

      def freeze
        @lazies_at_depth.default_proc = nil
        @lazies_at_depth.freeze
        super
      end

      def run(trace_query_lazy: nil)
        with_trace_query_lazy(trace_query_lazy) do
          while !@lazies_at_depth.empty?
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
        end
      end

      def run_isolated
        new_dl = self.class.new
        res = nil
        new_dl.append_job {
          res = yield
        }
        new_dl.run
        res
      end

      def clear_cache; end

      def yield(_source)
        raise GraphQL::Error, "GraphQL::Dataloader is not running -- add `use GraphQL::Dataloader` to your schema to use Dataloader sources."
      end

      def append_job(callable = nil)
        callable ? callable.call : yield
        nil
      end

      def with(*)
        raise GraphQL::Error, "GraphQL::Dataloader is not running -- add `use GraphQL::Dataloader` to your schema to use Dataloader sources."
      end
    end
  end
end
