# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # You can use this to allow certain values for an argument.
      #
      # Usually, a {GraphQL::Schema::Enum} is better for this, because it's self-documenting.
      #
      # @example only allow certain values for an argument
      #
      #   argument :favorite_prime, Integer, required: true,
      #     validates: { inclusion: { in: [2, 3, 5, 7, 11, ... ] } }
      #
      class InclusionValidator < Validator
        # @param message [String]
        # @param in [Array] The values to allow
        def initialize(argument,
          message: "%{argument} is not included in the list",
          in:,
          **default_options
        )
          # `in` is a reserved word, so work around that
          @in_list = binding.local_variable_get(:in)
          @message = message
          super(argument, **default_options)
        end

        def validate(_object, _context, value)
          if !@in_list.include?(value)
            @message % { argument: argument.graphql_name }
          end
        end
      end
    end
  end
end
