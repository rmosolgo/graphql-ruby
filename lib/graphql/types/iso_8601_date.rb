# frozen_string_literal: true
module GraphQL
  module Types
    # This scalar takes `Date`s and transmits them as strings,
    # using ISO 8601 format.
    #
    # Use it for fields or arguments as follows:
    #
    #     field :published_at, GraphQL::Types::ISO8601Date, null: false
    #
    #     argument :deliver_at, GraphQL::Types::ISO8601Date, null: false
    #
    # Alternatively, use this built-in scalar as inspiration for your
    # own Date type.
    class ISO8601Date < GraphQL::Schema::Scalar
      description "An ISO 8601-encoded date"

      # @param value [Date,Time,DateTime,String]
      # @return [String]
      def self.coerce_result(value, _ctx)
        Date.parse(value.to_s).iso8601
      end

      # @param str_value [String]
      # @return [Date]
      def self.coerce_input(str_value, _ctx)
        Date.iso8601(str_value)
      rescue ArgumentError, TypeError
        # Invalid input
        nil
      end
    end
  end
end
