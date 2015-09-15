module GraphQL
  module Relay
    class ConnectionField
      ARGUMENT_DEFINITIONS = [
          [:first, GraphQL::INT_TYPE],
          [:after, GraphQL::STRING_TYPE],
          [:last, GraphQL::INT_TYPE],
          [:before, GraphQL::STRING_TYPE],
          [:order, GraphQL::STRING_TYPE],
        ]

      DEFAULT_ARGUMENTS = ARGUMENT_DEFINITIONS.reduce({}) do |memo, arg_defn|
        argument = GraphQL::Argument.new
        argument.name = arg_defn[0]
        argument.type = arg_defn[1]
        memo[argument.name.to_s] = argument
        memo
      end

      # Turn A GraphQL::Field into a connection by:
      # - Merging in the default argument
      # - Transforming its resolve function to return a connection object
      def self.create(underlying_field)
        underlying_field.arguments = underlying_field.arguments.merge(DEFAULT_ARGUMENTS)
        # TODO: make a public API on GraphQL::Field to expose this proc
        original_resolve = underlying_field.instance_variable_get(:@resolve_proc)
        underlying_field.resolve = get_connection_resolve(original_resolve)
        underlying_field
      end

      private

      def self.get_connection_resolve(underlying_resolve)
        -> (obj, args, ctx) {
          items = underlying_resolve.call(obj, args, ctx)
          if items == GraphQL::Query::DEFAULT_RESOLVE
            items = obj.public_send(name)
          end
          connection_class = GraphQL::Relay::BaseConnection.connection_for_items(items)
          connection_class.new(items, args)
        }
      end
    end
  end
end
