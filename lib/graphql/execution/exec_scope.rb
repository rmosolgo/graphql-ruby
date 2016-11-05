module GraphQL
  module Execution
    # Global, immutable environment for executing `query`.
    # Passed through all execution to provide type, fragment and field lookup.
    class ExecScope
      attr_reader :query, :schema

      def initialize(query)
        @query = query
        @schema = query.schema
      end

      def get_type(type)
        @schema.types[type]
      end

      def get_fragment(name)
        @query.fragments[name]
      end

      # This includes dynamic fields like __typename
      def get_field(type, name)
        @schema.get_field(type, name) || raise("No field named '#{name}' found for #{type}")
      end
    end
  end
end
