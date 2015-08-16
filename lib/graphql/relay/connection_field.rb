module GraphQL
  module Relay
    class ConnectionField
      def self.create(underlying_field)
        field = GraphQL::Field.define do
          argument :first, types.Int
          argument :after, types.ID
          argument :last, types.Int
          argument :before, types.ID

          type(-> { underlying_field.type })
          resolve -> (obj, args, ctx) {
            items = underlying_field.resolve(obj, args, ctx)
            underlying_field.type.connection_class.new(items, args)
          }
        end
      end
    end
  end
end
