module GraphQL
  # A collection of {ObjectType}s
  #
  # @example a union of types
  #
  #   PetUnion = GraphQL::UnionType.define do
  #     name "Pet"
  #     description "Animals that live in your house"
  #     possible_types [DogType, CatType, FishType]
  #   end
  #
  class UnionType < GraphQL::BaseType
    include GraphQL::BaseType::HasPossibleTypes
    attr_accessor :name, :description, :possible_types
    accepts_definitions :possible_types, :resolve_type

    def kind
      GraphQL::TypeKinds::UNION
    end

    def include?(child_type_defn)
      possible_types.include?(child_type_defn)
    end
  end
end
