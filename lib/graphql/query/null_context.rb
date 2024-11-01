# frozen_string_literal: true
require "graphql/query/context"
module GraphQL
  class Query
    # This object can be `ctx` in places where there is no query
    class NullContext < Context
      include Singleton

      class NullQuery
        def after_lazy(value)
          yield(value)
        end
      end

      class NullSchema < GraphQL::Schema
      end

      extend Forwardable

      attr_reader :schema, :query, :warden, :dataloader
      def_delegators GraphQL::EmptyObjects::EMPTY_HASH, :[], :fetch, :dig, :key?

      def initialize
        @query = NullQuery.new
        @dataloader = GraphQL::Dataloader::NullDataloader.new
        @schema = NullSchema
        @types = Schema::Visibility::Profile.pass_thru(context: self, schema: @schema)
        @warden = Schema::Warden::NullWarden.new(context: self, schema: @schema)
      end

      def types
        @types ||= Schema::Warden::VisibilityProfile.new(@warden)
      end
    end
  end
end
