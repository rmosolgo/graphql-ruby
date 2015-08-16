module GraphQL
  module Relay
    class Edge < GraphQL::ObjectType
      def initialize(record)
        @record = record
      end

      def cursor
        raise NotImplementedError
      end

      def node
        @record
      end

      def self.create_type(wrapped_type)
        GraphQL::ObjectType.define do
          name("#{wrapped_type.name}Edge")
          field :node, wrapped_type
          field :cursor, !types.String
        end
      end
    end
  end
end
