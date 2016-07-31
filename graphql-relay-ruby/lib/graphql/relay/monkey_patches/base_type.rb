class GraphQL::BaseType
  # Get the default connection type for this object type
  def connection_type
    @connection_type ||= define_connection
  end

  # Define a custom connection type for this object type
  def define_connection(**kwargs, &block)
    GraphQL::Relay::ConnectionType.create_type(self, **kwargs, &block)
  end

  # Get the default edge type for this object type
  def edge_type
    @edge_type ||= define_edge
  end

  # Define a custom edge type for this object type
  def define_edge(**kwargs, &block)
    GraphQL::Relay::EdgeType.create_type(self, **kwargs, &block)
  end
end
