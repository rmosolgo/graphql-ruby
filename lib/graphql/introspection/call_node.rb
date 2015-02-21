class GraphQL::Introspection::CallNode < GraphQL::Node
  exposes "GraphQL::Call"
  field.string(:name)
  field.string(:arguments)

  def arguments
    args = target.lambda.parameters
    args.shift
    args.map { |p| "#{p[1]} (#{p[0]})" }.join(", ")
  rescue StandardError => e
    raise "Errored on #{name} (#{self}): #{e}"
  end
end
