# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      class FormatValidator < Validator
        if !String.method_defined?(:match?)
          using GraphQL::StringMatchBackport
        end

        def initialize(argument,
          with: nil,
          without: nil,
          message: "%{argument} is invalid",
          **default_options
        )
          @with_pattern = with
          @without_pattern = without
          @message = message
          super(argument, **default_options)
        end

        def validate(_object, _context, value)
          if (@with_pattern && !value.match?(@with_pattern)) ||
              (@without_pattern && value.match?(@without_pattern))
            @message % { argument: argument.graphql_name }
          end
        end
      end
    end
  end
end
