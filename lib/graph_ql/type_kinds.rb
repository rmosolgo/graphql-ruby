module GraphQL::TypeKinds
  KIND_NAMES = %i{
    SCALAR
    OBJECT
    INTERFACE
    UNION
    ENUM
    INPUT_OBJECT
    LIST
    NON_NULL
  }
  KIND_NAMES.each do |type_kind|
    const_set(type_kind, type_kind)
  end
end
