class GraphQL::Types::ObjectField < GraphQL::Field
  def as_result
    node_type = self.class.type || self.name
    node_class = GraphQL::SCHEMA.get_type(node_type)
    node = node_class.new(finished_value, query: query, fields: fields)
    node.as_result
  end
end