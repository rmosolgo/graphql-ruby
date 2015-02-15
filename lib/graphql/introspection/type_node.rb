class GraphQL::Introspection::TypeNode < GraphQL::Node
  cursor :name

  field :name,
     description: "The name of the node",
     type: :string

  field :description,
    description: "Description of the node",
    type: :string

  field :fields,
    type: :connection,
    method: :field_nodes,
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Introspection::FieldNode"

  def name
    type_class.schema_name
  end

  def description
    type_class.description
  end

  def field_nodes
    type_class.all_fields
  end

  private

  def type_class
    @type_class ||= @target
  end
end

