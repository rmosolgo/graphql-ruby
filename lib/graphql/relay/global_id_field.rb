module GraphQL
  module Relay
    # @example Create a field that returns the global ID for an object
    #   RestaurantType = GraphQL::ObjectType.define do
    #     name "Restaurant"
    #     field :id, field: GraphQL::Relay::GlobalIdField.new("Restaurant")
    #   end
    class GlobalIdField < GraphQL::Field
      def initialize(type_name, property: :id)
        self.arguments = {}
        self.type = !GraphQL::ID_TYPE
        self.resolve = -> (obj, args, ctx) {
          GraphQL::Relay::GlobalNodeIdentification.to_global_id(type_name, obj.public_send(property))
        }
      end
    end
  end
end
