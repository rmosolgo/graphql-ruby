# frozen_string_literal: true
module GraphQL
  module Define
    # Turn argument configs into a {GraphQL::Argument}.
    module AssignArgument
      def self.call(target, name, type = nil, description = nil, **rest, &block)
        argument = if block_given?
          GraphQL::Argument.define(&block)
        else
          GraphQL::Argument.new
        end

        unsupported_keys = rest.keys - [:default_value]
        if unsupported_keys.any?
          raise ArgumentError.new("unknown keyword#{unsupported_keys.length > 1 ? 's' : ''}: #{unsupported_keys.join(', ')}")
        end

        argument.name = name.to_s
        type && argument.type = type
        description && argument.description = description
        rest.key?(:default_value) && argument.default_value = rest[:default_value]

        target.arguments[name.to_s] = argument
      end
    end
  end
end
