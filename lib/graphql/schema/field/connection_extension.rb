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
          yield(object, next_args)
        end

        def after_resolve(value:, object:, arguments:, context:, memo:)
          if value.is_a? GraphQL::ExecutionError
            # This isn't even going to work because context doesn't have ast_node anymore
            context.add_error(value)
            nil
          elsif value.nil?
            nil
          else
            if object.is_a?(GraphQL::Schema::Object)
              object = object.object
            end
            connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(value)
            connection_class.new(
              value,
              arguments,
              field: field,
              max_page_size: field.max_page_size,
              parent: object,
              context: context,
            )
          end
        end

      end
    end
  end
end
