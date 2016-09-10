module GraphQL
  module Relay
    class GlobalIdResolve
      def initialize(type_name:, property:)
        @property = property
        @type_name = type_name
      end

      def call(obj, args, ctx)
        id_value = obj.public_send(@property)
        ctx.query.schema.to_global_id(@type_name, id_value)
      end
    end
  end
end
