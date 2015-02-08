class GraphQL::Node::FieldNode < GraphQL::Node
  field :name, description: "The name of the field"
  field :description, description: "The description of the field"

  def name
    target.const_get(:NAME)
  end

  def description
    target.const_get(:DESCRIPTION)
  end
end