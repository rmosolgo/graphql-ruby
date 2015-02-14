class GraphQL::Types::ConnectionField < GraphQL::Field
  field_type "connection"

  ["connection_class_name", "node_class_name"].each do |method_name|
    define_method(method_name) do
      const_get(method_name.upcase)
    end
  end

  def connection_class
    query.const_get(connection_class_name) || GraphQL::Connection
  end

  def node_class
    query.const_get(node_class_name) || raise("Couldn't find node class #{node_class_name} for #{self.class}")
  end

  def as_node
    items = finished_value
    connection_class.new(
      items,
      query: query,
      node_class: node_class,
      fields: fields,
    )
  end

  def as_result
    as_node.as_result
  end
end
