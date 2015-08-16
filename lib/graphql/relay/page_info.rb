module GraphQL
  module Relay
    # Wrap a Connection and expose its page info
    PageInfo = GraphQL::ObjectType.define do
      name("PageInfo")
      description("Metadata about a connection")
      field :hasNextPage, !types.Boolean, property: :has_next_page
      field :hasPreviousPage, !types.Boolean, property: :has_previous_page
    end
  end
end
