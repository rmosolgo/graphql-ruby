# This is raised when a node has a given field, but the class which
# this node wraps doesn't implement a corresponding method.
#
# @example A field with no underlying method
#   class Banana
#     def peel; end
#     def organic?; end
#   end
#
#   class BananaNode < GraphQL::Node
#     field.boolean(:is_organic)
#   end
#   # ^^ Error here, Banana doesn't have an `#is_organic` method!
#   # You can fix it like this:
#   class BananaNode
#     def is_organic
#       # `is_organic` delegates to `organic?`
#       organic?
#     end
#   end
#
class GraphQL::FieldNotImplementedError < GraphQL::Error
  def initialize(node_class, field_name)
    message = "#{node_class.name}##{field_name} is defined, but #{node_class.exposes_class_names.join(", ")} doesn't respond to `##{field_name}`!"
    super(message)
  end
end