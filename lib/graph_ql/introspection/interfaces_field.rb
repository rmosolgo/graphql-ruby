GraphQL::Introspection::InterfacesField = GraphQL::Field.new do |f, type|
  f.description "Interfaces which this object implements"
  f.type -> { !type[!GraphQL::Introspection::TypeType] }
  f.resolve -> (target, a, c) { target.kind.object? ? target.interfaces : nil }
end
