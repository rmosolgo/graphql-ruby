# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to specifically reject values that respond to `.blank?` and respond truthy for that method.
      #
      # @example Require a non-empty string for an argument
      #   argument :name, String, required: true, validate: { allow_blank: false }
      class AllowBlankValidator < Validator
        def initialize(allow_blank_positional = nil, allow_blank: nil, message: "%{validated} can't be blank", **default_options)
          @message = message
          super(**default_options)
          @allow_blank = allow_blank.nil? ? allow_blank_positional : allow_blank
        end

        def validate(_object, _context, value)
          if value.respond_to?(:blank?) && value.blank?
            if (value.nil? && validation_parameter(@allow_null)) || validation_parameter(@allow_blank)
              # pass
            else
              validation_parameter(@message)
            end
          end
        end
      end
    end
  end
end
