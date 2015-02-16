class GraphQL::Introspection::CallNode < GraphQL::Node
  field :name, type: :string
  field :arguments, type: :string
  def name
    target[:name]
  end

  def arguments
    args = target[:lambda].parameters
    args.shift
    args.map { |p| "#{p[1]} (#{p[0]})" }.join(", ")
  end
end
