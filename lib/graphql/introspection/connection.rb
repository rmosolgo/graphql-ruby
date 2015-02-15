class GraphQL::Introspection::Connection < GraphQL::Connection
  field :count, method: :size
end