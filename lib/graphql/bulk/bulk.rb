module GraphQL
  module Bulk
    require "graphql/bulk/visitors/add_pagination_to_query_visitor"
    require "graphql/bulk/visitors/add_typename_to_query_visitor"
    require "graphql/bulk/visitors/connection_node_extraction_visitor"
    require "graphql/bulk/visitors/connection_removal_visitor"
    require "graphql/bulk/base_query_splitter"
    require "graphql/bulk/connection_query_splitter"
    require "graphql/bulk/debug"
    require "graphql/bulk/errors"
    require "graphql/bulk/query_splitter_service"
  end
end
