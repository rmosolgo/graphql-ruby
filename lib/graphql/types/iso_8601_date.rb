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
      specified_by_url "https://tools.ietf.org/html/rfc3339"

      # **Parameters**
      #
      # - `value` (`Date, Time, DateTime, String`)
      #
      # **Returns**
      #
      # - `String`
      #
      # :call-seq:
      #   coerce_result(Date | Time | DateTime | String value, _ctx) -> String
      def self.coerce_result(value, _ctx)
        Date.parse(value.to_s).iso8601
      end

      # **Parameters**
      #
      # - `str_value` (`String, Date, DateTime, Time`)
      #
      # **Returns**
      #
      # - `Date, nil`
      #
      # :call-seq:
      #   coerce_input(value, ctx) -> Date | nil
      def self.coerce_input(value, ctx)
        if value.is_a?(::Date)
          value
        elsif value.is_a?(::DateTime)
          value.to_date
        elsif value.is_a?(::Time)
          value.to_date
        elsif value.nil?
          nil
        else
          Date.iso8601(value)
        end
      rescue ArgumentError, TypeError
        err = GraphQL::DateEncodingError.new(value)
        ctx.schema.type_error(err, ctx)
      end
    end
  end
end
