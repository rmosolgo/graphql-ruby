# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module Scoped
        # This is called when a field has `scope: true`.
        # The field's return type class receives this call.
        #
        # By default, it's a no-op. Override it to scope your objects.
        #
        # @param items [Object] Some list-like object (eg, Array, ActiveRecord::Relation)
        # @param context [GraphQL::Query::Context]
        # @return [Object] Another list-like object, scoped to the current context
        def scope_items(items, context)
          items
        end
      end
    end
  end
end
