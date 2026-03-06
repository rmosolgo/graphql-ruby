# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class LoadArgumentStep
        def initialize(field_resolve_step:, arguments:, argument_type:, argument_definition:)
          @field_resolve_step = field_resolve_step
          @arguments = arguments
          @argument_definition = argument_definition
          @argument_type = argument_type
          @loaded_value = nil
        end

        def value
          @loaded_value = @field_resolve_step.sync(@loaded_value)
          assign_value
        end

        def call
          context = @field_resolve_step.selections_step.query.context
          field_definition = @field_resolve_step.field_definition
          # This is for legacy compat:
          object_from_id_receiver = if (r = field_definition.resolver)
            r.new(field: field_definition, context: context, object: nil)
          else
            field_definition
          end
          begin
            @loaded_value = if @argument_type.list?
              arg_value.map {  |inner_id|
                object_from_id_receiver.load_and_authorize_application_object(@argument_definition, inner_id, context)
              }
            else
              object_from_id_receiver.load_and_authorize_application_object(@argument_definition, arg_value, context)
            end

            # TODO enqueue as lazy instead
            if (runner = @field_resolve_step.runner).resolves_lazies && runner.schema.lazy?(@loaded_value)
              runner.dataloader.lazy_at_depth(@field_resolve_step.path.size, self)
            else
              assign_value
            end

          rescue GraphQL::RuntimeError => err
            @loaded_value = err
          rescue StandardError => stderr
            @loaded_value = begin
              context.query.handle_or_reraise(stderr)
            rescue GraphQL::ExecutionError => ex_err
              ex_err
            end
          end
        end

        private

        def assign_value
          # TODO signal this error somehow??
          if @loaded_value.is_a?(GraphQL::Error)
            @loaded_value.path = path
            return @loaded_value
          end

          @arguments[@argument_definition.keyword] = @loaded_value
        ensure
          field_pending_steps = @field_resolve_step.pending_steps
          field_pending_steps.delete(self)
          if field_pending_steps.size == 0
            field_resolve_step.field_pending_steps = nil
          end
        end
      end
    end
  end
end
