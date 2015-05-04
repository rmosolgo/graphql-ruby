# Every {Node} class has a {FieldDefiner} instance that
# enables the `field.{something}` API.
#
# When you call `field.{type}({method_name})`, you're creating a {FieldMapping}.
# The {FieldMapping} will expose the value from `method_name` with nodes of type `type`.
class GraphQL::FieldDefiner
  attr_reader :owner_class
  def initialize(owner_class)
    @owner_class = owner_class
  end

  # `method_name` is used as a field type and looked up against {GraphQL::SCHEMA}.
  # `args[0]` is the name for the field of that type.
  # `args[1]` is the description of the field
  # Alternatively, `method_name` can be used as the  field name & `args[0]` may be the description.
  def method_missing(method_name, *args, &block)
    if args.length == 1 && args[0].is_a?(String)
      field_name = method_name
      field_desc = args[0]
    elsif args.length == 2
      field_name = args[0]
      field_desc = args[1]
    else
      field_name = args[0] || method_name
      raise "You must provide a description for `#{owner_class.name}.#{field_name}`"
    end
    map_field(field_name, field_desc, type: method_name)
  end

  private

  def map_field(field_name, field_description, type: nil)
    field_name = field_name.to_s
    field_description = field_description.to_s
    mapping = GraphQL::Field.new(
      name: field_name,
      description: field_description,
      type: type.to_s,
    )
    owner_class.own_fields[field_name] = mapping
  end
end