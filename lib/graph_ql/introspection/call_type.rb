class GraphQL::Introspection::CallType < GraphQL::Node
  exposes "GraphQL::Call"
  desc 'A call that can be made on a node'
  field.string(:name, "The identifier for this call")
  field.string(:arguments, "Arguments accepted by this call")

  def arguments
    args = target.lambda.parameters
    args.shift
    args.map { |p| "#{p[1]} (#{p[0]})" }.join(", ")
  rescue StandardError => e
    raise "Errored on #{name} (#{self}): #{e}"
  end
end
