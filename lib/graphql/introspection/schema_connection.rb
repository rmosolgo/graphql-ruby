class GraphQL::Introspection::SchemaConnection < GraphQL::Connection
  field :count, method: :size
end