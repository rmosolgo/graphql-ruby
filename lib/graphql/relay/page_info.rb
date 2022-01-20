# frozen_string_literal: true
module GraphQL
  module Relay
    # Wrap a Connection and expose its page info
    PageInfo = GraphQL::Types::Relay::PageInfo.graphql_definition(silence_deprecation_warning: true)
  end
end
