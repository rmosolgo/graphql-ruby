class GraphQL::Schema
  attr_reader :nodes, :calls
  def initialize
    @nodes = []
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

  def add_node(node_class)
    @nodes << node_class
  end

  def get_node(identifier)
    @nodes.find { |n| n.schema_name == identifier } ||  raise(GraphQL::NodeNotDefinedError.new(identifier))
  end

  def node_names
    @nodes.map(&:schema_name)
  end
end