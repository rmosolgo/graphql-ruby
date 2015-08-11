# A wrapper to implement `__schema`
class GraphQL::Introspection::SchemaField
  DEFINITION = Proc.new { |f, wrapped_type|
    f.description("This GraphQL schema")
    f.type(!GraphQL::Introspection::SchemaType)
    f.resolve -> (o, a, c) { wrapped_type }
  }

  def self.create(wrapped_type)
     GraphQL::Field.new { |f| DEFINITION.call(f, wrapped_type) }
  end
end
