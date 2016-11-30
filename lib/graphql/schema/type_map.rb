# frozen_string_literal: true
module GraphQL
  class Schema
    # Stores `{ name => type }` pairs for a given schema.
    # It behaves like a hash except for a couple things:
    #  - if you use `[key]` and that key isn't defined, 💥!
    #  - if you try to define the same key twice, 💥!
    #
    # If you want a type, but want to handle the undefined case, use {#fetch}.
    class TypeMap
      extend Forwardable
      def_delegators :@storage, :key?, :keys, :values, :to_h, :fetch, :each, :each_value

      def initialize
        @storage = {}
      end

      def [](key)
        @storage[key] || raise("No type found for '#{key}'")
      end

      def []=(key, value)
        if @storage.key?(key)
          raise("Duplicate type definition found for name '#{key}'")
        else
          @storage[key] = value
        end
      end
    end
  end
end
