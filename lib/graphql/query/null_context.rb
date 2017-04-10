# frozen_string_literal: true
module GraphQL
  class Query
    # This object can be `ctx` in places where there is no query
    class NullContext
      attr_reader :schema, :query, :warden

      def initialize
        @query = nil
        @schema = GraphQL::Schema.new
        @warden = GraphQL::Schema::Warden.new(
          GraphQL::Schema::NullMask,
          context: self,
          schema: @schema,
        )
      end

      class << self
        extend Forwardable

        def instance
          @instance = self.new
        end

        def_delegators :instance, :query, :schema, :warden
      end
    end
  end
end
