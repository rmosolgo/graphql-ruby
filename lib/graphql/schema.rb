class GraphQL::Schema
  attr_reader :types, :calls, :connections
  def initialize
    @types = {}
    @connections = {}
    @calls = []
  end

  def add_call(call_class)
    @calls << call_class
  end

  def get_call(identifier)
    @calls.find { |c| c.schema_name == identifier } || raise(GraphQL::RootCallNotDefinedError.new(identifier))
  end

  def call_names
    @calls.map(&:schema_name)
  end

  def add_type(node_class)
    existing_name = @types.key(node_class)
    if existing_name
      @types.delete(existing_name)
    end
    @types[node_class.schema_name] = node_class
  end

  def get_type(identifier)
    @types[identifier.to_s] || raise(GraphQL::NodeNotDefinedError.new(identifier))
  end

  def add_connection(node_class)
    existing_name = @connections.key(node_class)
    if existing_name
      @connections.delete(existing_name)
    end
    @connections[node_class.schema_name] = node_class
  end

  def get_connection(identifier)
    @connections[identifier] || raise(GraphQL::NodeNotDefinedError.new(identifier))
  end

  def type_names
    @types.keys
  end
end