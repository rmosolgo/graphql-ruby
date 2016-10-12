module GraphQL
  module Relay
    module EdgeType
      ### Ruby 1.9.3 unofficial support
      # def self.create_type(wrapped_type, name: nil, &block)
      def self.create_type(wrapped_type, options = {}, &block)
        name = options.fetch(:name, nil)

        GraphQL::ObjectType.define do
          name("#{wrapped_type.name}Edge")
          description "An edge in a connection."
          field :node, wrapped_type, "The item at the end of the edge."
          field :cursor, !types.String, "A cursor for use in pagination."
          block && instance_eval(&block)
        end
      end
    end
  end
end
