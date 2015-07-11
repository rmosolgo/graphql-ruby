GraphQL::TypeKindEnum = GraphQL::Enum.new do |e|
  e.name "__TypeKind"
  e.description "The kinds of types in this GraphQL system"
  GraphQL::TypeKinds::KIND_NAMES.each do |kind_name|
    e.value(kind_name)
  end
end
