# frozen_string_literal: true
require "graphql/schema/visibility/subset"
require "graphql/schema/visibility/migration"

module GraphQL
  class Schema
    class Visibility
      def self.use(schema, preload: nil, migration_errors: false)
        schema.visibility = self.new(schema, preload: preload)
        schema.use_schema_visibility = true
        if migration_errors
          schema.subset_class = Migration
        end
      end

      def initialize(schema, preload:)
        @schema = schema
        @cached_subsets = {}

        if preload.nil? && defined?(Rails) && Rails.env.production?
          preload = true
        end

        if preload

        end
      end
    end
  end
end
