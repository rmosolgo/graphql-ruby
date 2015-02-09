class GraphQL::Introspection::FieldsEdge < GraphQL::Edge
  field :count
  call :first, -> (prev_items, first) { prev_items.first(first.to_i)}
  call :last, -> (prev_items, last) { prev_items.last(last.to_i)}
end