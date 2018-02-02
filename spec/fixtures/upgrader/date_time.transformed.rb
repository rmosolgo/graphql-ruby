# frozen_string_literal: true

module Platform
  module Scalars
    class DateTime < Platform::Scalars::Base
      description "An ISO-8601 encoded UTC date string."

      def self.coerce_input(value, context)
        begin
          Time.iso8601(value)
        rescue ArgumentError, ::TypeError
        end
      end

      def self.coerce_result(value, context)
        return nil unless value
        value.utc.iso8601
      end
    end
  end
end
