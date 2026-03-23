# frozen_string_literal: true
require "graphql/query/context"
module GraphQL
  class Query
    # This object can be `ctx` in places where there is no query
    class NullContext < Context
      def self.instance
        @instance ||= self.new
      end

      def self.instance=(new_inst)
        @instance = new_inst
      end

      class NullQuery
        def after_lazy(value)
          yield(value)
        end
      end

      class NullSchema < GraphQL::Schema
      end

      extend Forwardable

      attr_reader :schema, :query, :warden, :dataloader
      def_delegators GraphQL::EmptyObjects::EMPTY_HASH, :[], :fetch, :dig, :key?, :to_h

      def initialize(schema: NullSchema)
        @query = NullQuery.new
        @dataloader = GraphQL::Dataloader::NullDataloader.new
        @schema = schema
        @warden = Schema::Warden::NullWarden.new(context: self, schema: @schema)
        @types = @warden.visibility_profile
        freeze
      end
    end
  end
end
