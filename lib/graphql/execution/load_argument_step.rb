# frozen_string_literal: true
module GraphQL
  module Execution
    class LoadArgumentStep
      def initialize(field_resolve_step:, arguments:, load_receiver:, argument_value:, argument_definition:, argument_key:)
        @field_resolve_step = field_resolve_step
        @load_receiver = load_receiver
        @arguments = arguments
        @argument_value = argument_value
        @argument_definition = argument_definition
        @argument_key = argument_key
        @loaded_value = nil
        @is_authorized = true
      end

      def value
        @field_resolve_step.set_current_field
        schema = @field_resolve_step.runner.schema
        @loaded_value = schema.sync_lazy(@loaded_value)
        assign_value
      rescue GraphQL::UnauthorizedError => auth_err
        @is_authorized = false
        schema.unauthorized_object(auth_err)
      rescue GraphQL::RuntimeError => err
        @loaded_value = if err.is_a?(Schema::Subscription::EarlyUnsubscribe)
          err.unsubscribed_result
        else
          err
        end
        assign_value
      rescue StandardError => stderr
        begin
          @field_resolve_step.selections_step.query.handle_or_reraise(stderr, field: @field_definition, arguments: @arguments, object: nil)
        rescue GraphQL::ExecutionError => ex_err
          @loaded_value = ex_err
        end
        assign_value
      ensure
        @field_resolve_step.set_current_field(nil)
      end

      def call
        @field_resolve_step.set_current_field
        context = @field_resolve_step.selections_step.query.context
        @loaded_value = begin
          @load_receiver.load_and_authorize_application_object(@argument_definition, @argument_value, context)
        rescue GraphQL::UnauthorizedError => auth_err
          @is_authorized = false
          context.schema.unauthorized_object(auth_err)
        end
        if (runner = @field_resolve_step.runner).resolves_lazies && runner.lazy?(@loaded_value)
          runner.dataloader.lazy_at_depth(@field_resolve_step.path.size, self)
        else
          assign_value
        end
      rescue GraphQL::RuntimeError => err
        @loaded_value = if err.is_a?(Schema::Subscription::EarlyUnsubscribe)
          @is_authorized = false
          err.unsubscribed_result
        else
          err
        end
        assign_value
      rescue StandardError => stderr
        @loaded_value = begin
          context.query.handle_or_reraise(stderr, field: @field_resolve_step.field_definition, arguments: @field_resolve_step.arguments, object: nil) # rubocop:disable Development/ContextIsPassedCop
        rescue GraphQL::ExecutionError => ex_err
          ex_err
        end
        assign_value
      ensure
        @field_resolve_step.set_current_field(nil)
      end

      private

      def assign_value
        if @loaded_value.is_a?(GraphQL::RuntimeError)
          @loaded_value.path = @field_resolve_step.path
          @field_resolve_step.arguments = @loaded_value
        elsif @is_authorized == false
          # An unauthorized_object hook ate the error
          @field_resolve_step.arguments = EmptyObjects::EMPTY_HASH
          field_pending_steps = @field_resolve_step.pending_steps
          field_pending_steps.clear
          @field_resolve_step.build_errors_result(nil, nil)
          return
        else
          query = @field_resolve_step.selections_step.query
          query.current_trace.object_loaded(@argument_definition, @loaded_value, query.context)
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
