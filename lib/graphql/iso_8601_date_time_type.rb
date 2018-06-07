# frozen_string_literal: true
module GraphQL
  # This scalar takes `DateTime`s and transmits them as strings,
  # using ISO 8601 format.
  #
  # To use it, require it in your project:
  #
  #     require "graphql/iso_8601_date_time_type"
  #
  # Then use it for fields or arguments:
  #
  #     field :created_at, GraphQL::ISO8601DateTimeType, null: false
  #
  #     argument :deliver_at, GraphQL::ISO8601DateTimeType, null: false
  #
  # Alternatively, use this built-in scalar as inspiration for your
  # own DateTime type.
  class ISO8601DateTimeType < GraphQL::Schema::Scalar
    description "An ISO 8601-encoded datetime"

    # @param value [DateTime]
    # @return [String]
    def self.coerce_result(value, _ctx)
      value.iso8601
    end

    # @param str_value [String]
    # @return [DateTime]
    def self.coerce_input(str_value, _ctx)
      DateTime.iso8601(str_value)
    rescue ArgumentError
      # Invalid input
      nil
    end
  end
end
