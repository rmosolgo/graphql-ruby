# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      # This can be used for Relay's `Node` interface,
      # or you can take it as inspiration for your own implementation
      # of the `Node` interface.
      module Node
        include Types::Relay::BaseInterface
        default_relay(true)
        description "An object with an ID."
        field(:id, ID, null: false, description: "ID of the object.")
      end
    end
  end
end
