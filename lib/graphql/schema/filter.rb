# frozen_string_literal: true

module GraphQL
  class Schema
    class Filter
      def initialize(field:)
        @field = field
      end

      def resolve_field(obj, args, ctx)
        yield(obj, args, ctx)
      end

      private

      # TODO rename, use elsewhere?
      # @api private
      class LazyThingy
        def initialize(schema, lazy_value, &then_block)
          @schema = schema
          @lazy_value = lazy_value
          @then_block = then_block
        end

        def value
          if defined?(@value)
            @value
          else
            method = @schema.lazy_method_name(@lazy_value)
            next_value = @lazy_value.public_send(method)
            @value = @then_block.call(next_value)
          end
        end
      end

      def after_lazy(schema, value)
        if schema.lazy?(value)
          LazyThingy.new(schema, value, &Proc.new)
        else
          yield(value)
        end
      end
    end

    class ConnectionFilter < Filter
      def initialize(field:)
        field.argument :after, "String", "Returns the elements in the list that come after the specified global ID.", required: false
        field.argument :before, "String", "Returns the elements in the list that come before the specified global ID.", required: false
        field.argument :first, "Int", "Returns the first _n_ elements from the list.", required: false
        field.argument :last, "Int", "Returns the last _n_ elements from the list.", required: false
        super
      end

      def resolve_field(obj, args)
        inner_args = args.dup
        inner_args.delete(:first)
        inner_args.delete(:after)
        inner_args.delete(:last)
        inner_args.delete(:before)
        nodes = yield(obj, inner_args)
        after_lazy(obj.context.schema, nodes) do |value|
          if value.nil?
            nil
          elsif value.is_a?(GraphQL::Execution::Execute::Skip)
            value
          elsif value.is_a? GraphQL::ExecutionError
            raise value
          else
            parent = obj.object
            connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(value)
            connection_class.new(value, args, field: @field.graphql_definition, max_page_size: @field.max_page_size, parent: parent, context: obj.context)
          end
        end
      end
    end
  end
end
