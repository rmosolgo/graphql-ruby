module GraphQL
  module Relay
    # Provided a GraphQL field which returns a collection of items,
    # `ConnectionField.create` modifies that field to expose those items
    # as a collection.
    #
    # The original resolve proc is used to fetch items,
    # then a connection implementation is fetched with {BaseConnection.connection_for_items}.
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

      # Turn A GraphQL::Field into a connection by:
      # - Merging in the default arguments
      # - Transforming its resolve function to return a connection object
      # @param [GraphQL::Field] A field which returns items to be wrapped as a connection
      # @param max_page_size [Integer] The maximum number of items which may be requested (if a larger page is requested, it is limited to this number)
      # @return [GraphQL::Field] A field which serves a connections
      def self.create(underlying_field, max_page_size: nil)
        underlying_field.arguments = DEFAULT_ARGUMENTS.merge(underlying_field.arguments)
        original_resolve = underlying_field.resolve_proc
        underlying_field.resolve = get_connection_resolve(underlying_field.name, original_resolve, max_page_size: max_page_size)
        underlying_field
      end

      private

      # Wrap the original resolve proc
      # so you capture its value, then wrap it in a
      # connection implementation
      def self.get_connection_resolve(field_name, underlying_resolve, max_page_size: nil)
        GraphQL::Relay::ConnectionResolve.new(field_name, underlying_resolve, max_page_size: max_page_size)
      end
    end
  end
end
