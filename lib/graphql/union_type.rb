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
    attr_accessor :name, :description
    accepts_definitions :possible_types, :resolve_type

    def kind
      GraphQL::TypeKinds::UNION
    end

    def include?(child_type_defn)
      possible_types.include?(child_type_defn)
    end

    def possible_types=(new_possible_types)
      @clean_possible_types = nil
      @dirty_possible_types = new_possible_types
    end

    def possible_types
      @clean_possible_types ||= begin
        @dirty_possible_types.map { |type| GraphQL::BaseType.resolve_related_type(type) }
      rescue
        @dirty_possible_types
      end
    end
  end
end
