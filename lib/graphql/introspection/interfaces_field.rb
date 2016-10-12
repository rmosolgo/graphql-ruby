GraphQL::Introspection::InterfacesField = GraphQL::Field.define do
  type -> { types[!GraphQL::Introspection::TypeType] }
  resolve ->(target, a, c) { target.kind.object? ? target.interfaces : nil }
end
