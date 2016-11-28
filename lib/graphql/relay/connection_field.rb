module GraphQL
  module Relay
    # Provided a GraphQL field which returns a collection of nodes,
    # `ConnectionField.create` modifies that field to expose those nodes
    # as a collection.
    #
    # The original resolve proc is used to fetch nodes,
    # then a connection implementation is fetched with {BaseConnection.connection_for_nodes}.
    class ConnectionField
      ARGUMENT_DEFINITIONS = [
          ["first", GraphQL::INT_TYPE, "Returns the first _n_ elements from the list."],
          ["after", GraphQL::STRING_TYPE, "Returns the elements in the list that come after the specified global ID."],
          ["last", GraphQL::INT_TYPE, "Returns the last _n_ elements from the list."],
          ["before", GraphQL::STRING_TYPE, "Returns the elements in the list that come before the specified global ID."],
        ]

      DEFAULT_ARGUMENTS = ARGUMENT_DEFINITIONS.reduce({}) do |memo, arg_defn|
        argument = GraphQL::Argument.new
        name, type, description = arg_defn
        argument.name = name
        argument.type = type
        argument.description = description
        memo[argument.name.to_s] = argument
        memo
      end

      # Build a connection field from a {GraphQL::Field} by:
      # - Merging in the default arguments
      # - Transforming its resolve function to return a connection object
      # @param underlying_field [GraphQL::Field] A field which returns nodes to be wrapped as a connection
      # @param max_page_size [Integer] The maximum number of nodes which may be requested (if a larger page is requested, it is limited to this number)
      # @return [GraphQL::Field] A redefined field with connection behavior
      def self.create(underlying_field, max_page_size: nil)
        connection_arguments = DEFAULT_ARGUMENTS.merge(underlying_field.arguments)
        original_resolve = underlying_field.resolve_proc
        connection_resolve = GraphQL::Relay::ConnectionResolve.new(underlying_field, original_resolve, max_page_size: max_page_size)
        underlying_field.redefine(resolve: connection_resolve, arguments: connection_arguments)
      end
    end
  end
end
