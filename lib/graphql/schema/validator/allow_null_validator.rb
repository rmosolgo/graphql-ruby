# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to specifically reject or permit `nil` values (given as `null` from GraphQL).
      class AllowNullValidator < Validator
        def initialize(allow_null_positional, allow_null: nil, message: "%{validated} can't be null", **default_options)
          @message = message
          super(**default_options)
          @allow_null = allow_null.nil? ? allow_null_positional : allow_null
        end

        def validate(_object, _context, value)
          if !@allow_null && value.nil?
            @message
          end
        end

        def validates_null?
          true
        end
      end
    end
  end
end
