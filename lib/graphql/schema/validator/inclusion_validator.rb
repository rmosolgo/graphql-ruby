# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      class InclusionValidator < Validator
        def initialize(argument,
          message: "%{argument} is not included in the list",
          in:,
          **default_options
        )
          # `in` is a keyword, so work around that
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
