module GraphQL
  class Query
    # Turn Ruby values into something useful for query execution
    class RubyInput
      def initialize(type, incoming_value)
        @type = type
        @incoming_value = incoming_value
      end

      def graphql_value
        @type.coerce_input!(@incoming_value)
      end

      def self.coerce(type, value)
        input = self.new(type, value)
        input.graphql_value
      end
    end
  end
end
