class GraphQL::DefinitionHelpers::DefinedByConfig::DefinitionConfig
  # Wraps a field definition with a ConnectionField
  def connection(name, type = nil, desc = nil, property: nil, &block)
    underlying_field = field(name, type, desc, property: property, &block)
    connection_field = GraphQL::Relay::ConnectionField.create(underlying_field)
    fields[name.to_s] = connection_field
  end

  alias :return_field :field
  alias :return_fields :fields

  def global_id_field(field_name)
    name || raise("You must define the type's name before creating a GlobalIdField")
    field(field_name, field: GraphQL::Relay::GlobalIdField.new(name))
  end

  # Support GlobalNodeIdentification
  attr_accessor :object_from_id_proc, :type_from_object_proc
  def object_from_id(proc)
    @object_from_id_proc = proc
  end

  def type_from_object(proc)
    @type_from_object_proc = proc
  end
end
