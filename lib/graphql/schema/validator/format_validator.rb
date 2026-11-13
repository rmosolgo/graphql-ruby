# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  class Schema
    class Validator
      # Use this to assert that string values match (or don't match) the given RegExp.
      #
      # **Examples**
      #
      # **Example: requiring input to match a pattern**
      #
      # ```ruby
      # argument :handle, String, required: true,
      #   validates: { format: { with: /\A[a-z0-9_]+\Z/ } }
      # ```
      #
      # **Example: reject inputs that match a pattern**
      #
      # ```ruby
      # argument :word_that_doesnt_begin_with_a_vowel, String, required: true,
      #   validates: { format: { without: /\A[aeiou]/ } }
      #
      # # It's pretty hard to come up with a legitimate use case for `without:`
      # ```
      class FormatValidator < Validator
        # **Parameters**
        #
        # - `with` (`RegExp, nil`)
        # - `without` (`Regexp, nil`)
        # - `message` (`String`)
        #
        # :call-seq:
        #   initialize(RegExp | nil with:, Regexp | nil without:, String message:, **default_options)
        #: (?with: Regexp | Proc | nil, ?without: Regexp | Proc | nil, ?message: String | Proc, **untyped default_options) -> void
        def initialize(
          with: nil,
          without: nil,
          message: "%{validated} is invalid",
          **default_options
        )
          @with_pattern = with #: Regexp | Proc | nil
          @without_pattern = without #: Regexp | Proc | nil
          @message = message #: String | Proc
          super(**default_options)
        end

        #: (untyped _object, GraphQL::Query::Context _context, untyped value) -> String?
        def validate(_object, _context, value)
          if permitted_empty_value?(value)
            # Do nothing
          elsif value.nil? ||
              (@with_pattern && !value.match?(validation_parameter(@with_pattern))) ||
              (@without_pattern && value.match?(validation_parameter(@without_pattern)))
            validation_parameter(@message)
          end
        end
      end
    end
  end
end
