class GraphQL::Introspection::CallNode < GraphQL::Node
  field :name, type: :string

  def name
    target[:name]
  end
end
