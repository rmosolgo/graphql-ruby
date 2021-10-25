# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to specifically reject values that respond to `.blank?` and respond truthy for that method.
      class AllowBlankValidator < Validator
        def initialize(allow_blank_positional, allow_blank: nil, message: "%{validated} can't be blank", **default_options)
          @message = message
          super(**default_options)
          @allow_blank = allow_blank.nil? ? allow_blank_positional : allow_blank
        end

        def validate(_object, _context, value)
          if value.respond_to?(:blank?) && value.blank?
            if @allow_blank
              # TODO how does this work in rails? Should `allow_null` have the same escape hatch?
              PASSES_VALIDATION
            else
              @message
            end
          end
        end

        def validates_null?
          true
        end
      end
    end
  end
end
