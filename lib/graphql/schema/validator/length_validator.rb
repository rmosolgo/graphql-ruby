# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to enforce a `.length` restriction on incoming values. It works for both Strings and Lists.
      #
      # **Examples**
      #
      # **Example: Allow no more than 10 IDs**
      #
      # ```ruby
      # argument :ids, [ID], required: true, validates: { length: { maximum: 10 } }
      # ```
      #
      # **Example: Require three selections**
      #
      # ```ruby
      # argument :ice_cream_preferences, [ICE_CREAM_FLAVOR], required: true, validates: { length: { is: 3 } }
      # ```
      class LengthValidator < Validator
        # **Parameters**
        #
        # - `maximum` (`Integer`)
        # - `too_long` (`String`) — Used when `maximum` is exceeded or value is greater than `within`
        # - `minimum` (`Integer`)
        # - `too_short` (`String`) — Used with value is less than `minimum` or less than `within`
        # - `is` (`Integer`) — Exact length requirement
        # - `wrong_length` (`String`) — Used when value doesn't match `is`
        # - `within` (`Range`) — An allowed range (becomes `minimum:` and `maximum:` under the hood)
        # - `message` (`String`)
        def initialize(
          maximum: nil, too_long: "%{validated} is too long (maximum is %{count})",
          minimum: nil, too_short: "%{validated} is too short (minimum is %{count})",
          is: nil, within: nil, wrong_length: "%{validated} is the wrong length (should be %{count})",
          message: nil,
          **default_options
        )
          if within && (minimum || maximum)
            raise ArgumentError, "`length: { ... }` may include `within:` _or_ `minimum:`/`maximum:`, but not both"
          end
          # Under the hood, `within` is decomposed into `minimum` and `maximum`
          @maximum = maximum || (within && within.max)
          @too_long = message || too_long
          @minimum = minimum || (within && within.min)
          @too_short = message || too_short
          @is = is
          @wrong_length = message || wrong_length
          super(**default_options)
        end

        def validate(_object, _context, value)
          return if permitted_empty_value?(value) # pass in this case
          length = value.nil? ? 0 : value.length
          if (current_max = validation_parameter(@maximum)) && length > current_max
            partial_format(validation_parameter(@too_long), { count: current_max })
          elsif (current_min = validation_parameter(@minimum)) && length < current_min
            partial_format(validation_parameter(@too_short), { count: current_min })
          elsif (current_is = validation_parameter(@is)) && length != current_is
            partial_format(validation_parameter(@wrong_length), { count: current_is })
          end
        end
      end
    end
  end
end
