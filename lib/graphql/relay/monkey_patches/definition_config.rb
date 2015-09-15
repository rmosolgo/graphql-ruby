class GraphQL::DefinitionHelpers::DefinedByConfig::DefinitionConfig
  # Wraps a field definition with a ConnectionField
  # - applies default fields
  # - wraps the resolve proc to make a connection
  #
  def connection(name, type = nil, desc = nil, property: nil, &block)
    # Wrap the given block to define the default args
    definition_block = -> (config) {
      argument :first, types.Int
      argument :after, types.String
      argument :last, types.Int
      argument :before, types.String
      argument :order, types.String
      self.instance_eval(&block) if block_given?
    }
    connection_field = field(name, type, desc, property: property, &definition_block)
    # Wrap the defined resolve proc
    # TODO: make a public API on GraphQL::Field to expose this proc
    original_resolve = connection_field.instance_variable_get(:@resolve_proc)
    connection_resolve = -> (obj, args, ctx) {
      items = original_resolve.call(obj, args, ctx)
      if items == GraphQL::Query::DEFAULT_RESOLVE
        method_name = property || name
        p "Obj: #{obj}  ##{method_name}"
        items = obj.public_send(method_name)
      end
      connection_class = GraphQL::Relay::BaseConnection.connection_for_items(items)
      connection_class.new(items, args)
    }
    connection_field.resolve = connection_resolve
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
