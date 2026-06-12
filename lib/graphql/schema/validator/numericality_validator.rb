# frozen_string_literal: true
module GraphQL
  class Schema
    class Validator
      # Use this to assert numerical comparisons hold true for inputs.
      #
      # @example Require a number between 0 and 1
      #
      #   argument :batting_average, Float, required: true, validates: { numericality: { within: 0..1 } }
      #
      # @example Require the number 42
      #
      #   argument :the_answer, Integer, required: true, validates: { numericality: { equal_to: 42 } }
      #
      # @example Require a real number
      #
      #   argument :items_count, Integer, required: true, validates: { numericality: { greater_than_or_equal_to: 0 } }
      #
      class NumericalityValidator < Validator
        # @param greater_than [Integer]
        # @param greater_than_or_equal_to [Integer]
        # @param less_than [Integer]
        # @param less_than_or_equal_to [Integer]
        # @param equal_to [Integer]
        # @param other_than [Integer]
        # @param odd [Boolean]
        # @param even [Boolean]
        # @param within [Range]
        # @param message [String] used for all validation failures
        def initialize(
            greater_than: nil, greater_than_or_equal_to: nil,
            less_than: nil, less_than_or_equal_to: nil,
            equal_to: nil, other_than: nil,
            odd: nil, even: nil, within: nil,
            message: "%{validated} must be %{comparison} %{target}",
            null_message: Validator::AllowNullValidator::MESSAGE,
            **default_options
          )

          @greater_than = greater_than
          @greater_than_or_equal_to = greater_than_or_equal_to
          @less_than = less_than
          @less_than_or_equal_to = less_than_or_equal_to
          @equal_to = equal_to
          @other_than = other_than
          @odd = odd
          @even = even
          @within = within
          @message = message
          @null_message = null_message
          super(**default_options)
        end

        def validate(object, context, value)
          if permitted_empty_value?(value)
            # pass in this case
          elsif value.nil? # @allow_null is handled in the parent class
            validation_parameter(@null_message)
          elsif (current_greater_than = validation_parameter(@greater_than)) && value <= current_greater_than
            partial_format(validation_parameter(@message), { comparison: "greater than", target: current_greater_than })
          elsif (current_greater_than_or_equal_to = validation_parameter(@greater_than_or_equal_to)) && value < current_greater_than_or_equal_to
            partial_format(validation_parameter(@message), { comparison: "greater than or equal to", target: current_greater_than_or_equal_to })
          elsif (current_less_than = validation_parameter(@less_than)) && value >= current_less_than
            partial_format(validation_parameter(@message), { comparison: "less than", target: current_less_than })
          elsif (current_less_than_or_equal_to = validation_parameter(@less_than_or_equal_to)) && value > current_less_than_or_equal_to
            partial_format(validation_parameter(@message), { comparison: "less than or equal to", target: current_less_than_or_equal_to })
          elsif (current_equal_to = validation_parameter(@equal_to)) && value != current_equal_to
            partial_format(validation_parameter(@message), { comparison: "equal to", target: current_equal_to })
          elsif (current_other_than = validation_parameter(@other_than)) && value == current_other_than
            partial_format(validation_parameter(@message), { comparison: "something other than", target: current_other_than })
          elsif validation_parameter(@even) && !value.even?
            (partial_format(validation_parameter(@message), { comparison: "even", target: "" })).strip
          elsif validation_parameter(@odd) && !value.odd?
            (partial_format(validation_parameter(@message), { comparison: "odd", target: "" })).strip
          elsif (current_within = validation_parameter(@within)) && !current_within.include?(value)
            partial_format(validation_parameter(@message), { comparison: "within", target: current_within })
          end
        end
      end
    end
  end
end
