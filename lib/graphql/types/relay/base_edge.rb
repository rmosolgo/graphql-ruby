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
      # See [Relay::BaseConnection](rdoc-ref:Relay::BaseConnection) for connection types
      #
      # **Examples**
      #
      # **Example: Making a UserEdge type**
      #
      # ```ruby
      # # Make a base class for your app
      # class Types::BaseEdge < GraphQL::Types::Relay::BaseEdge
      # end
      #
      # # Then extend your own base class
      # class Types::UserEdge < Types::BaseEdge
      #   node_type(Types::User)
      # end
      # ```
      class BaseEdge < GraphQL::Schema::Object
        include Types::Relay::EdgeBehaviors
      end
    end
  end
end
