# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      class ConnectionExtension < GraphQL::Schema::FieldExtension
        def apply
          field.argument :after, "String", "Returns the elements in the list that come after the specified cursor.", required: false
          field.argument :before, "String", "Returns the elements in the list that come before the specified cursor.", required: false
          field.argument :first, "Int", "Returns the first _n_ elements from the list.", required: false
          field.argument :last, "Int", "Returns the last _n_ elements from the list.", required: false
        end

        # Remove pagination args before passing it to a user method
        def resolve(object:, arguments:, context:)
          next_args = arguments.dup
          next_args.delete(:first)
          next_args.delete(:last)
          next_args.delete(:before)
          next_args.delete(:after)
          yield(object, next_args, arguments)
        end

        def resolve_next(objects:, arguments:, context:)
          next_args = arguments.dup
          next_args.delete(:first)
          next_args.delete(:last)
          next_args.delete(:before)
          next_args.delete(:after)
          yield(objects, next_args, arguments)
        end

        def after_resolve(value:, object:, arguments:, context:, memo:)
          original_arguments = memo
          context.query.after_lazy(value) do |resolved_value|
            context.schema.connections.populate_connection(field, object.object, resolved_value, original_arguments, context)
          end
        end

        def after_resolve_next(**kwargs)
          raise "This should never be called -- it's hardcoded in execution instead."
        end
      end
    end
  end
end
