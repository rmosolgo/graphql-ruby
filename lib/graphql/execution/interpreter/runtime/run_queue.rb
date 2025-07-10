# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter
      class Runtime
        class RunQueue
          def initialize(runtime:)
            @runtime = runtime
            @current_flush = []
            @dataloader = runtime.dataloader
            @lazies_at_depth = runtime.lazies_at_depth
            @running_eagerly = false
          end

          def append_step(step)
            @dataloader.append_job(step)
            # @current_flush << step
          end

          def complete(eager: false)
            @dataloader.run
          #   # p [self.class, __method__, eager, caller(1,1).first, @current_flush.size]
          #   prev_eagerly = @running_eagerly
          #   @running_eagerly = eager
          #   while (fl = @current_flush) && fl.any?
          #     @current_flush = []
          #     @steps_to_rerun_after_lazy = []
          #     while fl.any?
          #       while (next_step = fl.shift)
          #         @dataloader.append_job(next_step)

          #         if @running_eagerly && @current_flush.any?
          #           # This is for mutations. If a mutation parent field enqueues any child fields,
          #           # we need to run those before running other mutation parent fields.
          #           fl.unshift(*@current_flush)
          #           @current_flush.clear
          #         end
          #       end

          #       if @current_flush.any?
          #         fl.concat(@current_flush)
          #         @current_flush.clear
          #       else
          #         @dataloader.run
          #         fl.concat(@steps_to_rerun_after_lazy)
          #         @steps_to_rerun_after_lazy.clear
          #         Interpreter::Resolve.resolve_each_depth(@lazies_at_depth, @dataloader)
          #       end
          #     end
          #   end
          # ensure
          #   @running_eagerly = prev_eagerly
          end
        end
      end
    end
  end
end
