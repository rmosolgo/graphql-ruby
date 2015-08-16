module GraphQL
  module Relay
    class GlobalIdField < GraphQL::Field
      def initialize(type_name, property: :id)
        @arguments = {}
        @type = !GraphQL::ID_TYPE
        @resolve_proc = -> (obj, args, ctx) {
          Node.to_global_id(type_name, obj.public_send(property))
        }
      end
    end
  end
end
