# frozen_string_literal: true
module GraphQL
  class Query
    # This object can be `ctx` in places where there is no query
    class NullContext
      class NullWarden < GraphQL::Schema::Warden
        def visible?(t); true; end
        def visible_field?(t); true; end
        def visible_type?(t); true; end
      end

      attr_reader :schema, :query, :warden, :dataloader

      def initialize
        @query = nil
        @dataloader = GraphQL::Dataloader::NullDataloader.new
        @schema = GraphQL::Schema.new
        @warden = NullWarden.new(
          GraphQL::Filter.new,
          context: self,
          schema: @schema,
        )
      end

      def [](key); end

      def interpreter?
        false
      end

      class << self
        extend Forwardable

        def [](key); end

        def instance
          @instance = self.new
        end

        def_delegators :instance, :query, :schema, :warden, :interpreter?, :dataloader
      end
    end
  end
end
