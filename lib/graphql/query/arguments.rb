module GraphQL
  class Query
    # Read-only access to values, normalizing all keys to strings
    #
    # {Arguments} recursively wraps the input in {Arguments} instances.
    class Arguments
      extend Forwardable

      def initialize(values)
        @values = values.inject({}) do |memo, (inner_key, inner_value)|
          memo[inner_key.to_s] = wrap_value(inner_value)
          memo
        end
      end

      # @param [String, Symbol] name or index of value to access
      # @return [Object] the argument at that key
      def [](key)
        @values[key.to_s]
      end

      def_delegators :@values, :keys, :values, :each

      private

      def wrap_value(value)
        if value.is_a?(Array)
          value.map { |item| wrap_value(item) }
        elsif value.is_a?(Hash)
          self.class.new(value)
        else
          value
        end
      end
    end
  end
end
