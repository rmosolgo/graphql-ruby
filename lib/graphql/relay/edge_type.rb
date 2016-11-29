# frozen_string_literal: true
module GraphQL
  module Relay
    module EdgeType
      def self.create_type(wrapped_type, name: nil, &block)
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
