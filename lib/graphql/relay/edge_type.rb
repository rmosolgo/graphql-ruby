module GraphQL
  module Relay
    module EdgeType
      def self.create_type(wrapped_type, name: nil, &block)
        GraphQL::ObjectType.define do
          name("#{wrapped_type.name}Edge")
          description "An edge in a connection."
          field :node, "The item at the end of the edge.", wrapped_type
          field :cursor, "A cursor for use in pagination.", !types.String
          block && instance_eval(&block)
        end
      end
    end
  end
end
