# frozen_string_literal: true
# typed: strict
module GraphQL
  module Introspection
    # This query is used by graphql-client so don't add the includeDeprecated
    # argument for inputFields since the server may not support it. Two stage
    # introspection queries will be required to handle this in clients.
    INTROSPECTION_QUERY = GraphQL::Introspection.query #: String
  end
end

