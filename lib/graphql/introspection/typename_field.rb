module GraphQL
  module Introspection
    # A wrapper to create `__typename`.
    class TypenameField
      def self.create(wrapped_type)
        GraphQL::Field.define do
          name "__typename"
          description "The name of this type"
          type -> { !GraphQL::STRING_TYPE }
          resolve -> (obj, a, c) { wrapped_type.name }
        end
      end
    end
  end
end
