# This node doesn't have a field with that name.
class GraphQL::FieldNotDefinedError < GraphQL::Error
  def initialize(node_class, field_name)
    class_name = node_class.name
    defined_field_names = node_class.all_fields.keys
    super("#{class_name}##{field_name} was requested, but it isn't defined. Defined fields are: #{defined_field_names}")
  end
end