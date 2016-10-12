module GraphQL
  module Define
    # Turn argument configs into a {GraphQL::Argument}.
    module AssignArgument
      ### Ruby 1.9.3 unofficial support
      # def self.call(target, name, type = nil, description = nil, default_value: nil, &block)
      def self.call(target, name, type = nil, description = nil, options = {}, &block)
        type = options.fetch(:type, nil)
        description = options.fetch(:description, nil)
        default_value = options.fetch(:default_value, nil)

        argument = if block_given?
          GraphQL::Argument.define(&block)
        else
          GraphQL::Argument.new
        end
        argument.name = name.to_s
        type && argument.type = type
        description && argument.description = description
        !default_value.nil? && argument.default_value = default_value

        target.arguments[name.to_s] = argument
      end
    end
  end
end
