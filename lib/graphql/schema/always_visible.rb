# frozen_string_literal: true
# typed: strict
module GraphQL
  class Schema
    module AlwaysVisible
      #: (singleton(GraphQL::Schema) schema, **untyped opts) -> void
      def self.use(schema, **opts)
        schema.use(GraphQL::Schema::Visibility, profiles: { nil => {} })
        schema.extend(self)
      end

      #: (untyped _member, GraphQL::Query::Context _context) -> bool
      def visible?(_member, _context)
        true
      end
    end
  end
end
