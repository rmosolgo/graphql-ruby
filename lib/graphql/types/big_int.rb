# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  module Types
    class BigInt < GraphQL::Schema::Scalar
      description "Represents non-fractional signed whole numeric values. Since the value may exceed the size of a 32-bit integer, it's encoded as a string."

      #: (untyped value, GraphQL::Query::Context _ctx) -> (::Numeric | false | nil)
      def self.coerce_input(value, _ctx)
        value && parse_int(value)
      rescue ArgumentError
        nil
      end

      #: (untyped value, GraphQL::Query::Context _ctx) -> ::String
      def self.coerce_result(value, _ctx)
        value.to_i.to_s
      end

      #: (untyped value) -> ::Numeric
      def self.parse_int(value)
        value.is_a?(Numeric) ? value : Integer(value, 10)
      end
    end
  end
end
