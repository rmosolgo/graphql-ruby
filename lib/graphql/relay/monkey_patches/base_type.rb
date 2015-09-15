class GraphQL::BaseType
  def connection_type
    @connection_type ||= GraphQL::Relay::BaseConnection.create_type(self)
  end
end
