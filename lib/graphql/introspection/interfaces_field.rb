GraphQL::Introspection::InterfacesField = GraphQL::Field.define do
  type -> { types[!GraphQL::Introspection::TypeType] }
  resolve ->(target, a, ctx) {
    if target.kind == GraphQL::TypeKinds::OBJECT
      ctx.warden.each_interface(target).to_a
    else
      nil
    end
  }
end
