# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # @example
      #   argument :ids, [ID], validates: { length: { maximum: 10 } }
      class LengthValidator < Validator
        def initialize(argument,
          maximum: nil, too_long: "%{argument} is too long (maximum is %{count})",
          minimum: nil, too_short: "%{argument} is too short (minimum is %{count})",
          is: nil, within: nil, wrong_length: "%{argument} is the wrong length (should be %{count})",
          message: nil
        )
          if within && (minimum || maximum)
            raise ArgumentError, "`length: { ... }` may include `within:` _or_ `minimum:`/`maximum:`, but not both"
          end
          @argument = argument
          @maximum = maximum || (within && within.max)
          @too_long = message || too_long
          @minimum = minimum || (within && within.min)
          @too_short = message || too_short
          @is = is
          @wrong_length = message || wrong_length
        end

        def validate(_object, _context, value)
          if @maximum && value.length > @maximum
            @too_long % { argument: @argument.graphql_name, count: @maximum }
          elsif @minimum && value.length < @minimum
            @too_short % { argument: @argument.graphql_name, count: @minimum }
          elsif @is && value.length != @is
            @wrong_length % { argument: @argument.graphql_name, count: @is }
          end
        end
      end
    end
  end
end
