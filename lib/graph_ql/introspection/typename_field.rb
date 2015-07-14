# A wrapper to create `__typename`.
# Uses `.create` because I couldn't figure out how to
# pass `DEFINITION` via `super` (then I could extend GraphQL::Field)
class GraphQL::Introspection::TypenameField
  DEFINITION = Proc.new { |f, wrapped_type|
    f.name "__typename"
    f.description "The name of this type"
    f.type -> { !GraphQL::STRING_TYPE }
    f.resolve -> (obj, a, c) { wrapped_type.name }
  }

  def self.create(wrapped_type)
     GraphQL::Field.new { |f| DEFINITION.call(f, wrapped_type) }
  end
end
