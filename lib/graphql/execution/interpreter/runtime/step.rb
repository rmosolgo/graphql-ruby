# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class Runtime
        module Step
          attr_accessor :was_scoped

          # @return [Boolean] True if `value` was lazy and this step was re-enqueued
          def reenqueue_if_lazy?(value)
            if @runtime.lazy?(value)
              @runtime.lazies_at_depth[depth] << self
              @runtime.steps_to_rerun_after_lazy << self
              true
            else
              false
            end
          end

          def call
            # TODO use a `current_step`-type thing for this
            rs = @runtime.get_current_runtime_state
            rs.current_result = self.current_result
            rs.current_result_name = self.current_result_name
            rs.current_step = self
            run_step
          end
        end
      end
    end
  end
end
