GraphQL::Introspection::TypeKindEnum = GraphQL::EnumType.define do
  name "__TypeKind"
  description "The kinds of types in this GraphQL system"
  GraphQL::TypeKinds::KIND_NAMES.each do |kind_name|
    value(kind_name)
  end
end
