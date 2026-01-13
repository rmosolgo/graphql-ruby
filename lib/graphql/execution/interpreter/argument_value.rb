# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A container for metadata regarding arguments present in a GraphQL query.
      # @see Interpreter::Arguments#argument_values for a hash of these objects.
      class ArgumentValue
        def initialize(definition:, value:, original_value:, default_used:)
          @arguments = nil
          @definition = definition
          @value = value
          @original_value = original_value
          @default_used = default_used
        end

        attr_writer :arguments

        # @private implements Dataloader API
        def call
          if NOT_CONFIGURED.equal?(@value)
            context = @arguments.context
            value = definition.type.coerce_input(@original_value, context)
            value = definition.prepare_value(@arguments.parent_object, value, context: context)
            if definition.loads && !definition.from_resolver?
              value = definition.load_and_authorize_value(definition.owner, value, context)
              while value.is_a?(Array) && value.any? { |v| NOT_CONFIGURED.equal?(v) }
                @arguments.context.dataloader.yield # TODO hack to wait for other work to finish
              end
            end
            @value = value
          end
        rescue StandardError => err
          @value = err
          context = @arguments.context
          context.schema.handle_or_reraise(context, err)
        end

        # @private is this value finished being dataloaded?
        def finished?
          !NOT_CONFIGURED.equal?(@value)
        end

        # @return [Object] The Ruby-ready value for this Argument
        attr_reader :value

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
