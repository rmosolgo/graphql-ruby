# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to validate each member of an array value.
      #
      # **Examples**
      #
      # **Example: validate format of all strings in an array**
      #
      # ```ruby
      # argument :handles, [String],
      #   validates: { all: { format: { with: /\A[a-z0-9_]+\Z/ } } }
      # ```
      #
      # **Example: multiple validators can be combined**
      #
      # ```ruby
      # argument :handles, [String],
      #   validates: { all: { format: { with: /\A[a-z0-9_]+\Z/ }, length: { maximum: 32 } } }
      # ```
      #
      # **Example: any type can be used**
      #
      # ```ruby
      # argument :choices, [Integer],
      #   validates: { all: { inclusion: { in: 1..12 } } }
      # ```
      class AllValidator < Validator
        def initialize(validated:, allow_blank: false, allow_null: false, **validators)
          super(validated: validated, allow_blank: allow_blank, allow_null: allow_null)

          @validators = Validator.from_config(validated, validators)
        end

        def validate(object, context, value)
          return EMPTY_ARRAY if permitted_empty_value?(value)

          all_errors = EMPTY_ARRAY

          value.each do |subvalue|
            @validators.each do |validator|
              errors = validator.validate(object, context, subvalue)
              if errors &&
                  (errors.is_a?(Array) && errors != EMPTY_ARRAY) ||
                  (errors.is_a?(String))
                if all_errors.frozen? # It's empty
                  all_errors = []
                end
                if errors.is_a?(String)
                  all_errors << errors
                else
                  all_errors.concat(errors)
                end
              end
            end
          end

          unless all_errors.frozen?
            all_errors.uniq!
          end

          all_errors
        end
      end
    end
  end
end
