GraphQL::Introspection::InterfacesField = GraphQL::Field.define do
  description "Interfaces which this object implements"
  type -> { types[!GraphQL::Introspection::TypeType] }
  resolve -> (target, a, c) { target.kind.object? ? target.interfaces.sort_by(&:name) : nil }
end
