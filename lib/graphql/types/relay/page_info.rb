# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # The return type of a connection's `pageInfo` field
      class PageInfo < Types::Relay::BaseObject
        default_relay true
        description "Information about pagination in a connection."
        field :has_next_page, Boolean, null: false,
          description: "When paginating forwards, are there more items?"

        field :has_previous_page, Boolean, null: false,
          description: "When paginating backwards, are there more items?"

        field :start_cursor, String, null: true,
          description: "When paginating backwards, the cursor to continue."

        field :end_cursor, String, null: true,
          description: "When paginating forwards, the cursor to continue."
      end
    end
  end
end
