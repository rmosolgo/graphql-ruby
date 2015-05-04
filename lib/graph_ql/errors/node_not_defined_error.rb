# There's no Node defined for that kind of object.
class GraphQL::NodeNotDefinedError < GraphQL::Error
  def initialize(node_name)
    super("#{node_name} was requested but was not found. Defined nodes are: #{GraphQL::SCHEMA.type_names}")
  end
end