class GraphQL::Field
  attr_reader :name, :method, :description, :edge_class_name, :node_class_name
  def initialize(name:, method: nil, description: nil, edge_class_name: nil, node_class_name: nil)
    @name = name
    @method = method || name
    @edge_class_name = edge_class_name
    @node_class_name = node_class_name
  end
end