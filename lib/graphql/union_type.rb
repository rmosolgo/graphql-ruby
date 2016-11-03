module GraphQL
  # A Union is is a collection of object types which may appear in the same place.
  #
  # The members of a union are declared with `possible_types`.
  #
  # @example A union of object types
  #   MediaUnion = GraphQL::UnionType.define do
  #     name "Media"
  #     description "Media objects which you can enjoy"
  #     possible_types [AudioType, ImageType, VideoType]
  #   end
  #
  # A union itself has no fields; only its members have fields.
  # So, when you query, you must use fragment spreads to access fields.
  #
  # @example Querying for fields on union members
  #  {
  #    searchMedia(name: "Jens Lekman") {
  #      ... on Audio { name, duration }
  #      ... on Image { name, height, width }
  #      ... on Video { name, length, quality }
  #    }
  #  }
  #
  class UnionType < GraphQL::BaseType
    accepts_definitions :possible_types, :resolve_type
    ensure_defined :possible_types

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
        if @dirty_possible_types.respond_to?(:map)
          @dirty_possible_types.map { |type| GraphQL::BaseType.resolve_related_type(type) }
        else
          @dirty_possible_types
        end
      end
    end
  end
end
