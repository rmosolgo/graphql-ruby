# frozen_string_literal: true

module GraphQL
  module Types
    class BigInt < GraphQL::Schema::Scalar
      description "Represents non-fractional signed whole numeric values. Since the value may exceed the size of a 32-bit integer, it's encoded as a string."

      def self.coerce_input(value, _ctx)
        value && Integer(value)
      rescue ArgumentError
        nil
      end

      def self.coerce_result(value, _ctx)
        value.to_i.to_s
      end
    end
  end
end
