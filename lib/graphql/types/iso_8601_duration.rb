# frozen_string_literal: true

module GraphQL
  module Types
    # This scalar takes `Durations`s and transmits them as strings,
    # using ISO 8601 format.
    #
    # Use it for fields or arguments as follows:
    #
    #     field :duration, Types::ISO8601Duration, null: false
    #
    #     argument :duration, Types::ISO8601Duration, null: false
    class ISO8601Duration < GraphQL::Schema::Scalar
      description 'An ISO 8601-encoded duration'

      # @param value [Duration, String]
      # @return [String]
      def self.coerce_result(value, _ctx)
        case value
        when ActiveSupport::Duration
          value.iso8601
        when ::String
          ActiveSupport::Duration.parse(value).iso8601
        else
          value.try(:iso8601)
        end
      rescue StandardError => e
        raise GraphQL::Error, <<-ERROR
              An incompatible object (#{value.class}) was
              given to #{self}. Make sure that only Durations
              and well-formatted Strings are used with this
              type. (#{e.message})"
        ERROR
      end

      # @param str_value [String]
      # @return [ActiveSupport::Duration]
      def self.coerce_input(str_value, _ctx)
        ActiveSupport::Duration.parse(str_value)
      rescue ArgumentError, TypeError
        # Invalid input
        nil
      end
    end
  end
end
