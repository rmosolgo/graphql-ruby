module GraphQL
  class Schema
    # @api private
    module NullMask
      def self.call(member, ctx)
        false
      end
    end
  end
end
