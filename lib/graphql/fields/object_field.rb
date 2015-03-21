class GraphQL::Fields::ObjectField < GraphQL::Field
  type "object"
  def as_result
    node_class = GraphQL::SCHEMA.type_for_object(finished_value)
    node = node_class.new(finished_value, query: query, fields: fields)
    node.as_result
  end
end