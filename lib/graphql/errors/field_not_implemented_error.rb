# This is raise when a node has a given field, but the class which
# this node wraps doesn't implement a corresponding method.
class GraphQL::FieldNotImplementedError < GraphQL::Error
  def initialize(node_class, field_name)
    message = "#{node_class.name}##{field_name} is defined, but #{node_class.exposes_class_names.join(", ")} doesn't respond to `##{field_name}`!"
    super(message)
  end
end