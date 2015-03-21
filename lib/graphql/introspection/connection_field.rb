class GraphQL::Introspection::ConnectionField < GraphQL::Fields::ConnectionField
  type :introspection_connection
  connection "GraphQL::Introspection::Connection"
end
