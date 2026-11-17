# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  class Schema
    class Validator
      # Use this to specifically reject or permit `nil` values (given as `null` from GraphQL).
      #
      # **Examples**
      #
      # **Example: require a non-null value for an argument if it is provided**
      #
      # ```ruby
      # argument :name, String, required: false, validates: { allow_null: false }
      # ```
      class AllowNullValidator < Validator
        MESSAGE = "%{validated} can't be null" #: String
        #: (?(bool | Proc | nil) allow_null_positional, ?allow_null: bool | Proc | nil, ?message: String | Proc, **untyped default_options) -> void
        def initialize(allow_null_positional = nil, allow_null: nil, message: MESSAGE, **default_options)
          @message = message #: String | Proc
          super(**default_options)
          @allow_null = allow_null.nil? ? allow_null_positional : allow_null
        end

        #: (untyped _object, GraphQL::Query::Context _context, untyped value) -> String?
        def validate(_object, _context, value)
          if value.nil? && !validation_parameter(@allow_null)
            validation_parameter(@message)
          end
        end
      end
    end
  end
end
