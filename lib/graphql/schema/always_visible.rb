# frozen_string_literal: true
module GraphQL
  class Schema
    class AlwaysVisible
      def self.use(schema, **opts)
        schema.warden_class = GraphQL::Schema::Warden::NullWarden
      end
    end
  end
end
