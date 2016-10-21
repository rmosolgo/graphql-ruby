module GraphQL
  module Relay
    class GlobalIdResolve
      ### Ruby 1.9.3 unofficial support
      # def initialize(type:)
      def initialize(options = {})
        type = options[:type]

        @type = type
      end

      def call(obj, args, ctx)
        ctx.query.schema.id_from_object(obj, @type, ctx)
      end
    end
  end
end
