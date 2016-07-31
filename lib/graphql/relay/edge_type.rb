module GraphQL
  module Relay
    module EdgeType
      def self.create_type(wrapped_type, name: nil, &block)
        GraphQL::ObjectType.define do
          name("#{wrapped_type.name}Edge")
          field :node, wrapped_type
          field :cursor, !types.String
          block && instance_eval(&block)
        end
      end
    end
  end
end
