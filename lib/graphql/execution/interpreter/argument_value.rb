# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A container for metadata regarding arguments present in a GraphQL query.
      # @see Interpreter::Arguments#argument_values for a hash of these objects.
      class ArgumentValue
        def initialize(definition:, value:, original_value:, default_used:, ast_node:)
          @arguments = nil
          @definition = definition
          @value = value
          @original_value = original_value
          @default_used = default_used
          @ast_node = ast_node
          @state = :initialized
        end

        attr_writer :arguments

        # Lazy api tODO conflicts with old attr_reader :value
        def value
          if @arguments.context&.schema&.lazy?(@value) # TODO InputObject still calls coerce_arguments which doesn't initialize this
            @value = @arguments.context.schema.sync_lazy(@value)
            @arguments.context.dataloader.append_job(self)
          end
          @value
        rescue GraphQL::UnauthorizedError => err
          @state = :finished
          context = @arguments.context
          @value = context.schema.unauthorized_object(err)
        rescue GraphQL::ExecutionError => exec_err
          @state = :errored
          context = @arguments.context
          exec_err.path ||= context.current_path
          exec_err.ast_node ||= @ast_node
          context.errors << exec_err
          @value = exec_err
        rescue StandardError => err
          @state = :finished
          context = @arguments.context
          @value = context.schema.handle_or_reraise(context, err)
        end

        # @private implements Dataloader API
        def call
          context = @arguments.context
          case @state
          when :initialized
            @value = definition.type.coerce_input(@original_value, context)
            @state = :coerced
          when :coerced
            @value = definition.prepare_value(@arguments.parent_object, @value, context: context)
            @state = :prepared
          when :prepared
            if definition.loads && !definition.from_resolver?
              @value = definition.load_and_authorize_value(definition.owner, @value, context)
              while @value.is_a?(Array) && @value.any? { |v| NOT_CONFIGURED.equal?(v) }
                @arguments.context.dataloader.yield # TODO hack to wait for other work to finish
              end
            end
            @state = :finished
          end

          if context.schema.lazy?(@value) # TODO use runtime cached version
            context.dataloader.lazy_at_depth(context[:current_result].depth, self)
          elsif @state != :finished
            # TODO non-recursive
            call
          end
        rescue GraphQL::UnauthorizedError => err
          @state = :errored
          context = @arguments.context
          @value = context.schema.unauthorized_object(err)
          @state = :finished
          @value
        rescue GraphQL::ExecutionError => exec_err
          @state = :errored
          exec_err.path ||= context.current_path
          exec_err.ast_node ||= @ast_node
          context.add_error(exec_err)
        rescue StandardError => err
          @state = :finished
          context = @arguments.context
          @value = context.schema.handle_or_reraise(context, err)
        end

        def completed?
          @state == :finished || @state == :errored
        end

        def errored?
          @state == :errored
        end

        attr_reader :state
        # # @return [Object] The Ruby-ready value for this Argument
        # attr_reader :value

        # @return [Object] The value of this argument _before_ `prepare` is applied.
        attr_reader :original_value

        # @return [GraphQL::Schema::Argument] The definition instance for this argument
        attr_reader :definition

        # @return [Boolean] `true` if the schema-defined `default_value:` was applied in this case. (No client-provided value was present.)
        def default_used?
          @default_used
        end
      end
    end
  end
end
