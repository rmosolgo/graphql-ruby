GraphQL::Introspection::InterfacesField = GraphQL::Field.new do |f|
  f.description "Interfaces which this object implements"
  f.type -> { !GraphQL::ListType.new(of_type: !GraphQL::Introspection::TypeType) }
  f.resolve -> (target, a, c) { target.kind.object? ? target.interfaces : nil }
end
