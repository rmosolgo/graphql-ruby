# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      class OneOf < GraphQL::Schema::Directive
        description "Indicates an Input Object is a OneOf Input Object."

        locations(
          GraphQL::Schema::Directive::INPUT_OBJECT
        )

        default_directive true

        module OneOfInputObjectSchema
          def argument(*args, **kwargs, &block)
            kwargs[:required] = false if kwargs[:required].nil?

            argument = super(*args, **kwargs, &block)
            validate_argument_non_null(argument)
            validate_argument_no_default(argument)

            argument
          end

          private

          def validate_argument_non_null(argument)
            return if argument.type.is_a?(Schema::LateBoundType)
            return unless argument.type.kind.non_null?

            raise ArgumentError, "Argument '#{graphql_name}.#{argument.name}' must be nullable " \
                                 "as it is part of a OneOf Type."
          end

          def validate_argument_no_default(argument)
            return unless argument.default_value?

            raise ArgumentError, "Argument '#{graphql_name}.#{argument.name}' cannot have a default value " \
                                 "as it is part of a OneOf Type."
          end
        end

        module OneOfInputObjectExecution
          def initialize(*, **)
            super

            validate_arguments!(@ruby_style_hash)
          end

          private

          def validate_arguments!(arguments)
            if arguments.count != 1 || arguments.each_value.first.nil?
              raise GraphQL::ExecutionError, "Exactly one argument must be provided and be non-null."
            end
          end
        end

        def initialize(target, **options)
          if !target.ancestors.include?(OneOfInputObjectExecution)
            target.extend(OneOfInputObjectSchema)
            target.include(OneOfInputObjectExecution)
          end

          super
        end
      end
    end
  end
end
