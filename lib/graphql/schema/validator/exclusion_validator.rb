# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to specifically reject values from an argument.
      #
      # @example disallow certain values
      #
      #   argument :favorite_non_prime, Integer, required: true,
      #     validates: { exclusion: { in: [2, 3, 5, 7, ... ]} }
      #
      class ExclusionValidator < Validator
        # @param message [String]
        # @param in [Array] The values to reject
        def initialize(argument,
          message: "%{argument} is reserved",
          in:,
          **default_options
        )
          # `in` is a reserved word, so work around that
          @in_list = binding.local_variable_get(:in)
          @message = message
          super(argument, **default_options)
        end

        def validate(_object, _context, value)
          if @in_list.include?(value)
            @message % { argument: argument.graphql_name }
          end
        end
      end
    end
  end
end
