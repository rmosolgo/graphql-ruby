# frozen_string_literal: true
module GraphQL
  module Define
    # Turn argument configs into a {GraphQL::Argument}.
    module AssignArgument
      def self.call(target, *args, **kwargs, &block)
        argument = GraphQL::Argument.from_dsl(*args, **kwargs, &block)
        target.arguments[argument.name] = argument
      end
    end
  end
end
