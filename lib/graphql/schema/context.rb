# frozen_string_literal: true

module GraphQL
  class Schema
    # @api private
    class Context
      extend Forwardable

      attr_reader :schema

      def_delegators :@provided_values, :[], :[]=, :to_h, :to_hash, :key?, :fetch, :dig

      def initialize(schema:, values:)
        @schema = schema
        @provided_values = values
      end
    end
  end
end
