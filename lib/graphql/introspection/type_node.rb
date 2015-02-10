class GraphQL::Introspection::TypeNode < GraphQL::Node
  cursor :name

  field :name, description: "The name of the node", type: "String"
  field :description, description: "Description of the node", type: "String"

  edges :fields,
    method: :field_nodes,
    edge_class_name: "GraphQL::Introspection::FieldsEdge",
    node_class_name: "GraphQL::Introspection::FieldNode"

  def self.call(type_name)
    new(type_name)
  end

  def name
    type_class.node_name
  end

  def description
    type_class.description
  end

  def field_nodes
    type_class.all_fields
  end

  private

  def type_class
    @type_class ||= query.get_node(@target)
  end
end

