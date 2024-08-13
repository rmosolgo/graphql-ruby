# frozen_string_literal: true
require "graphql/schema/visibility/subset"

module GraphQL
  class Schema
    class Visibility
      def self.use(schema)
        schema.visibility = self.new(schema)
        schema.use_schema_visibility = true
      end

      def initialize(schema)
        @schema = schema
      end
    end
  end
end
