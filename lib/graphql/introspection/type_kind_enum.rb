GraphQL::Introspection::TypeKindEnum = GraphQL::EnumType.define do
  name "__TypeKind"
  description "An enum describing what kind of type a given `__Type` is."
  GraphQL::TypeKinds::KIND_NAMES.each do |kind_name|
    value(kind_name, GraphQL::TypeKinds::TYPE_KIND_DESCRIPTIONS[kind_name.to_sym])
  end
end
