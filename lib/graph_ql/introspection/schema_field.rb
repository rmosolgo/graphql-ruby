# A wrapper to implement `__schema`
class GraphQL::Introspection::SchemaField
  def self.create(wrapped_type)
     GraphQL::Field.define do
       name("__schema")
       description("This GraphQL schema")
       type(!GraphQL::Introspection::SchemaType)
       resolve -> (o, a, c) { wrapped_type }
     end
  end
end
