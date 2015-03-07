# Every {Node} class has a {FieldDefiner} instance that
# enables the `field.{something}` API.
class GraphQL::FieldDefiner
  attr_reader :owner_class
  def initialize(owner_class)
    @owner_class = owner_class
  end

  # `method_name` is used as a field type and looked up against {GraphQL::SCHEMA}.
  # `args[0]` is the name for the field of that type.
  def method_missing(method_name, *args, &block)
    type = GraphQL::SCHEMA.get_field(method_name)
    if type.present?
      create_field(args[0], type: type, description: args[1])
    else
      super
    end
  end

  private

  def create_field(field_name, type: nil, description: nil)
    field_name = field_name.to_s
    field_class = GraphQL::Field.create_class({
      name: field_name,
      type: type,
      owner_class: owner_class,
      description: description,
    })

    field_class_name = field_name.camelize + "Field"
    owner_class.const_set(field_class_name, field_class)
    owner_class.own_fields[field_name] = field_class
  end
end