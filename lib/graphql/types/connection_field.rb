class GraphQL::Types::ConnectionField < GraphQL::Field
  type "connection"

  ["connection_class_name", "node_class_name"].each do |method_name|
    define_method(method_name) do
      const_get(method_name.upcase)
    end
  end

  def connection_class
    if connection_class_name.present?
      Object.const_get(connection_class_name)
    else
      GraphQL::SCHEMA.get_connection(name)
    end
  end

  def as_node
    items = finished_value
    connection_class.new(
      items,
      query: query,
      fields: fields,
    )
  end

  def as_result
    as_node.as_result
  end
end
