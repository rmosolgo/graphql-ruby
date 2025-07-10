# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class Runtime
        module Step
          def call
            step_finished = false
            while !step_finished
              # TODO use a `current_step`-type thing for this
              rs = @runtime.get_current_runtime_state
              rs.current_result = self.current_result
              rs.current_result_name = self.current_result_name
              step_result = run_step
              step_finished = step_finished?
              if !step_finished && @runtime.lazy?(step_result)
                @runtime.lazies_at_depth[depth] << self
                @runtime.steps_to_rerun_after_lazy << self
                step_finished = true # we'll come back around to it
              end
            end
          end
        end
      end
    end
  end
end
