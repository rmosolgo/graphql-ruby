# frozen_string_literal: true
module GraphQL
  class Schema
    module DefaultParseError
      def self.call(parse_error, ctx)
        ctx.errors.push(parse_error)
      end
    end
  end
end
