# frozen_string_literal: true
module GraphQL
  module Execution
    class LoadArgumentsStep
      def initialize(field_resolve_step:, arguments:, load_receiver:, argument_values:, argument_definition:)
        @field_resolve_step = field_resolve_step
        @load_receiver = load_receiver
        @arguments = arguments
        @argument_values = argument_values
        @argument_definition = argument_definition
        @loaded_values = Array.new(argument_values.size)
        @authorization_states = Array.new(argument_values.size, true)
        @errors = Array.new(argument_values.size)
        @remaining_values = argument_values.size
        @remaining_loads = argument_values.size
        @phase = :start
        @next_index = 0
        @lazy_indexes = []
      end

      def call
        case @phase
        when :start
          @phase = :loading
          enqueue_jobs(@argument_values.size)
        when :loading
          index = @next_index
          @next_index += 1
          load_value(index)
        when :resolving
          index = @lazy_indexes[@next_index]
          @next_index += 1
          resolve_lazy_value(index)
        else
          raise GraphQL::InvariantError, "Unexpected LoadArgumentsStep phase: #{@phase.inspect}"
        end
        nil
      end

      def value
        @phase = :resolving
        @next_index = 0
        enqueue_jobs(@lazy_indexes.size)
        nil
      end

      private

      def load_value(index)
        @field_resolve_step.set_current_field
        context = @field_resolve_step.selections_step.query.context
        begin
          @loaded_values[index] = begin
            @load_receiver.load_and_authorize_application_object(
              @argument_definition,
              @argument_values[index],
              context,
            )
          rescue GraphQL::UnauthorizedError => auth_err
            @authorization_states[index] = false
            context.schema.unauthorized_object(auth_err)
          end
          complete_load(index)
        rescue GraphQL::RuntimeError => err
          handle_runtime_error(index, err, loading: true)
          complete_load(index)
        rescue StandardError => stderr
          handle_standard_error(index, stderr)
          complete_load(index)
        ensure
          @field_resolve_step.set_current_field(nil)
        end
      end

      def resolve_lazy_value(index)
        @field_resolve_step.set_current_field
        schema = @field_resolve_step.runner.schema
        begin
          @loaded_values[index] = schema.sync_lazy(@loaded_values[index])
          complete_value(index)
        rescue GraphQL::UnauthorizedError => auth_err
          @authorization_states[index] = false
          schema.unauthorized_object(auth_err)
        rescue GraphQL::RuntimeError => err
          handle_runtime_error(index, err, loading: false)
          complete_value(index)
        rescue StandardError => stderr
          handle_standard_error(index, stderr)
          complete_value(index)
        ensure
          @field_resolve_step.set_current_field(nil)
        end
      end

      def handle_runtime_error(index, error, loading:)
        if error.is_a?(Schema::Subscription::EarlyUnsubscribe)
          @authorization_states[index] = false if loading
          @loaded_values[index] = error.unsubscribed_result
        else
          @loaded_values[index] = @errors[index] = error
        end
      end

      def handle_standard_error(index, error)
        query = @field_resolve_step.selections_step.query
        @loaded_values[index] = begin
          query.handle_or_reraise(
            error,
            field: @field_resolve_step.field_definition,
            arguments: @field_resolve_step.arguments, # rubocop:disable Development/ContextIsPassedCop
            object: nil,
          )
        rescue GraphQL::ExecutionError => execution_error
          execution_error
        end
      end

      def record_error(index)
        loaded_value = @loaded_values[index]
        @errors[index] = loaded_value if loaded_value.is_a?(GraphQL::RuntimeError)
      end

      def complete_load(index)
        record_error(index)
        load_completed(index)
      end

      def complete_value(index)
        record_error(index)
        value_completed(index)
      end

      def enqueue_jobs(count)
        dataloader = @field_resolve_step.runner.dataloader
        count.times { dataloader.append_job(self) }
      end

      def load_completed(index)
        runner = @field_resolve_step.runner
        if runner.resolves_lazies && runner.lazy?(@loaded_values[index])
          @lazy_indexes << index
        else
          value_completed(index)
        end

        @remaining_loads -= 1
        if @remaining_loads == 0 && !@lazy_indexes.empty?
          @phase = :waiting
          runner.dataloader.lazy_at_depth(@field_resolve_step.path.size, self)
        end
      end

      def value_completed(index)
        query = @field_resolve_step.selections_step.query
        if (error = @errors[index])
          error.path = @field_resolve_step.path
          @field_resolve_step.arguments = error
        elsif @authorization_states[index]
          loaded_value = @loaded_values[index]
          query.current_trace.object_loaded(@argument_definition, loaded_value, query.context)
          @arguments[index] = loaded_value
        else
          @field_resolve_step.arguments = EmptyObjects::EMPTY_HASH
          @field_resolve_step.pending_steps.clear
          @field_resolve_step.build_errors_result(nil, nil)
        end

        @remaining_values -= 1
        return if @remaining_values > 0 || (!@authorization_states[index] && error.nil?)

        finish
      end

      def finish
        @phase = :finished
        field_pending_steps = @field_resolve_step.pending_steps
        field_pending_steps.delete(self)
        if @field_resolve_step.arguments && field_pending_steps.empty? # rubocop:disable Development/ContextIsPassedCop
          @field_resolve_step.runner.add_step(@field_resolve_step)
        end
      end
    end
  end
end
