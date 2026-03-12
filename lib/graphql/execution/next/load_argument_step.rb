# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
      class LoadArgumentStep
        def initialize(field_resolve_step:, arguments:, load_receiver:, argument_value:, argument_definition:, argument_key:)
          @field_resolve_step = field_resolve_step
          @load_receiver = load_receiver
          @arguments = arguments
          @argument_value = argument_value
          @argument_definition = argument_definition
          @argument_key = argument_key
          @loaded_value = nil
        end

        def value
          @loaded_value = @field_resolve_step.sync(@loaded_value)
          assign_value
        end

        def call
          context = @field_resolve_step.selections_step.query.context
          @loaded_value = @load_receiver.load_and_authorize_application_object(@argument_definition, @argument_value, context)
          if (runner = @field_resolve_step.runner).resolves_lazies && runner.lazy?(@loaded_value)
            runner.dataloader.lazy_at_depth(@field_resolve_step.path.size, self)
          else
            assign_value
          end
        rescue GraphQL::RuntimeError => err
          @loaded_value = err
          assign_value
        rescue StandardError => stderr
          @loaded_value = begin
            context.query.handle_or_reraise(stderr)
          rescue GraphQL::ExecutionError => ex_err
            ex_err
          end
          assign_value
        end

        private

        def assign_value
          if @loaded_value.is_a?(GraphQL::Error)
            @loaded_value.path = @field_resolve_step.path
            @field_resolve_step.arguments = @loaded_value
          else
            @arguments[@argument_key] = @loaded_value
          end

          field_pending_steps = @field_resolve_step.pending_steps
          field_pending_steps.delete(self)
          if @field_resolve_step.arguments && field_pending_steps.size == 0 # rubocop:disable Development/ContextIsPassedCop
            @field_resolve_step.runner.add_step(@field_resolve_step)
          end
        end
      end
    end
  end
end
