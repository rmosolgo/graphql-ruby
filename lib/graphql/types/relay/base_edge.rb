# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # A class-based definition for Relay edges.
      #
      # Use this as a parent class in your app, or use it as inspiration for your
      # own base `Edge` class.
      #
      # For example, you may want to extend your own `BaseObject` instead of the
      # built-in `GraphQL::Schema::Object`.
      #
      # @example Making a UserEdge type
      #   # Make a base class for your app
      #   class Types::BaseEdge < GraphQL::Types::Relay::BaseEdge
      #   end
      #
      #   # Then extend your own base class
      #   class Types::UserEdge < Types::BaseEdge
      #     node_type(Types::User)
      #   end
      #
      # @see {Relay::BaseConnection} for connection types
      class BaseEdge < Types::Relay::BaseObject
        description "An edge in a connection."

        class << self
          # Get or set the Object type that this edge wraps.
          #
          # @param node_type [Class] A `Schema::Object` subclass
          # @param null [Boolean]
          def node_type(node_type = nil, null: true)
            if node_type
              @node_type = node_type
              # Add a default `node` field
              field :node, node_type, null: null, description: "The item at the end of the edge."
            end
            @node_type
          end

          def authorized?(obj, ctx)
            true
          end

          def accessible?(ctx)
            node_type.accessible?(ctx)
          end

          def visible?(ctx)
            node_type.visible?(ctx)
          end
        end


        field :cursor, String,
          null: false,
          description: "A cursor for use in pagination."
      end
    end
  end
end
