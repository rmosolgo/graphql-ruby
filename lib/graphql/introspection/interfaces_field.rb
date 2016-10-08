GraphQL::Introspection::InterfacesField = GraphQL::Field.define do
  type -> { types[!GraphQL::Introspection::TypeType] }
  resolve ->(target, a, c) {
    if target.kind.object?
      target.interfaces.select { |int| ctx.schema.visible_type?(int) }
    else
      nil
    end
  }
end
