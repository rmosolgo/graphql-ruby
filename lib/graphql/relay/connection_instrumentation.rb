# frozen_string_literal: true
module GraphQL
  module Relay
    # Provided a GraphQL field which returns a collection of nodes,
    # wrap that field to expose those nodes as a connection.
    #
    # The original resolve proc is used to fetch nodes,
    # then a connection implementation is fetched with {BaseConnection.connection_for_nodes}.
    module ConnectionInstrumentation
      def self.default_arguments
        @default_arguments ||= begin
          argument_definitions = [
            ["first", GraphQL::INT_TYPE, "Returns the first _n_ elements from the list."],
            ["after", GraphQL::STRING_TYPE, "Returns the elements in the list that come after the specified cursor."],
            ["last", GraphQL::INT_TYPE, "Returns the last _n_ elements from the list."],
            ["before", GraphQL::STRING_TYPE, "Returns the elements in the list that come before the specified cursor."],
          ]

          argument_definitions.reduce({}) do |memo, arg_defn|
            argument = GraphQL::Argument.new
            name, type, description = arg_defn
            argument.name = name
            argument.type = type
            argument.description = description
            memo[argument.name.to_s] = argument
            memo
          end
        end
      end

      # Build a connection field from a {GraphQL::Field} by:
      # - Merging in the default arguments
      # - Transforming its resolve function to return a connection object
      def self.instrument(type, field)
        if field.connection?
          connection_arguments = default_arguments.merge(field.arguments)
          original_resolve = field.resolve_proc
          original_lazy_resolve = field.lazy_resolve_proc
          connection_resolve = GraphQL::Relay::ConnectionResolve.new(field, original_resolve)
          connection_lazy_resolve = GraphQL::Relay::ConnectionResolve.new(field, original_lazy_resolve)
          field.redefine(
            resolve: connection_resolve,
            lazy_resolve: connection_lazy_resolve,
            arguments: connection_arguments,
          )
        else
          field
        end
      end
    end
  end
end
