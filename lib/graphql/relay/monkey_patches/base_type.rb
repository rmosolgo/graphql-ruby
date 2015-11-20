class GraphQL::BaseType
  def connection_type
    @connection_type ||= define_connection
  end

  def edge_type
    @edge_type ||= GraphQL::Relay::Edge.create_type(self)
  end

  def define_connection(&block)
    if !@connection_type.nil?
      raise("#{name}'s connection type was already defined, can't redefine it!")
    end
    @connection_type = GraphQL::Relay::BaseConnection.create_type(self, &block)
  end
end
