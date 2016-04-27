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
      def_delegators :@storage, :key?, :keys, :values, :fetch, :to_h

      # Used for detecting deprecated interface member inferrance
      attr_accessor :safely_discovered_types

      def initialize
        @storage = {}
        @safely_discovered_types = []
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

      def warnings
        interface_only_types = @storage.values - safely_discovered_types
        interface_only_types.map do |unsafe_type|
          "Type \"#{unsafe_type}\" was inferred from an interface's #possible_types. This won't be supported in the next version of GraphQL. Pass this type with the `types:` argument to `Schema.new` instead!"
        end
      end
    end
  end
end
