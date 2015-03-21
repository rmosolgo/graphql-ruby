class GraphQL::Fields::ConnectionField < GraphQL::Field
  type "connection"

  def connection_class
    if self.class.connection_class_name.present?
      Object.const_get(self.class.connection_class_name)
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

  class << self
    attr_accessor :connection_class_name
    def connection(connection_class_name)
      self.connection_class_name = connection_class_name
    end
  end
end
