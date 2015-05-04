# Raised when a query requests a field, but that field wasn't defined by the node.
#
# @example Requesting a field that doesn't exist
#   class UnicornNode < GraphQL::Node
#     field.string(:name)
#     field.color(:favorite_color)
#   end
#
#   # This query will raise a `FieldNotDefinedError`:
#   "unicorn(1) {
#      name,
#      favorite_color,
#      archnemesis
#   }"
#   # No such field `archnemesis`!
class GraphQL::FieldNotDefinedError < GraphQL::Error
  def initialize(node_class, field_name)
    class_name = node_class.name
    defined_field_names = node_class.all_fields.keys
    super("#{class_name}##{field_name} was requested, but it isn't defined. Defined fields are: #{defined_field_names}")
  end
end