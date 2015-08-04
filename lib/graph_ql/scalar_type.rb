module GraphQL
  # The parent type for scalars, eg {GraphQL::STRING_TYPE}, {GraphQL::INT_TYPE}
  #
  class ScalarType < GraphQL::ObjectType
    def kind
      GraphQL::TypeKinds::SCALAR
    end
  end
end
