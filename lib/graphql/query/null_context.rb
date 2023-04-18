# frozen_string_literal: true
module GraphQL
  class Query
    # This object can be `ctx` in places where there is no query
    class NullContext
      class NullQuery
      end

      class NullSchema < GraphQL::Schema
      end

      attr_reader :schema, :query, :warden, :dataloader

      def initialize
        @query = NullQuery.new
        @dataloader = GraphQL::Dataloader::NullDataloader.new
        @schema = NullSchema
        @warden = Schema::Warden::NullWarden.new(nil, context: self, schema: @schema)
      end

      def [](key); end

      def interpreter?
        true
      end

      class << self
        extend Forwardable

        def [](key); end

        def instance
          @instance ||= self.new
        end

        def_delegators :instance, :query, :warden, :schema, :interpreter?, :dataloader
      end
    end
  end
end
