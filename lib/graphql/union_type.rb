# frozen_string_literal: true
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
    ensure_defined :possible_types, :resolve_type, :resolve_type_proc

    attr_accessor :resolve_type_proc, :filter_possible_types_proc

    def initialize
      super
      @dirty_possible_types = []
      @clean_possible_types = nil
      @resolve_type_proc = nil
    end

    def initialize_copy(other)
      super
      @clean_possible_types = nil
      @dirty_possible_types = other.dirty_possible_types.dup
    end

    def kind
      GraphQL::TypeKinds::UNION
    end

    # @return [Boolean] True if `child_type_defn` is a member of this {UnionType}
    def include?(child_type_defn, ctx = GraphQL::Query::NullContext)
      possible_types(ctx).include?(child_type_defn)
    end

    def possible_types=(new_possible_types)
      @clean_possible_types = nil
      @dirty_possible_types = new_possible_types
    end

    # @return [Array<GraphQL::ObjectType>] Types which may be found in this union
    def possible_types(ctx = GraphQL::Query::NullContext)
      @clean_possible_types ||= begin
        if @dirty_possible_types.respond_to?(:map)
          @dirty_possible_types.map { |type| GraphQL::BaseType.resolve_related_type(type) }
        else
          @dirty_possible_types
        end
      end

      filter_possible_types(@clean_possible_types, ctx)
    end

    # Get a possible type of this {UnionType} by type name
    # @param type_name [String]
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [GraphQL::ObjectType, nil] The type named `type_name` if it exists and is a member of this {UnionType}, (else `nil`)
    def get_possible_type(type_name, ctx)
      type = ctx.query.get_type(type_name)
      type if type && ctx.query.schema.possible_types(self, ctx).include?(type)
    end

    # Check if a type is a possible type of this {UnionType}
    # @param type [String, GraphQL::BaseType] Name of the type or a type definition
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [Boolean] True if the `type` exists and is a member of this {UnionType}, (else `nil`)
    def possible_type?(type, ctx)
      type_name = type.is_a?(String) ? type : type.graphql_name
      !get_possible_type(type_name, ctx).nil?
    end

    # Filter possible types based on the current context
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [Array<GraphQL::ObjectType>] The types remaining after the filter is applied
    def filtered_possible_types(ctx)
      if @filtered_possible_types_proc
        @filtered_possible_types_proc.call(ctx)
      else
        []
      end
    end

    def filter_possible_types(types, ctx)
      original_types = types.map { |type| GraphQL::BaseType.resolve_related_type(type) }
      types_to_filter = filtered_possible_types(ctx).map { |type| GraphQL::BaseType.resolve_related_type(type) }

      original_types - types_to_filter
    end

    def resolve_type(value, ctx)
      ctx.query.resolve_type(self, value)
    end

    def resolve_type=(new_resolve_type_proc)
      @resolve_type_proc = new_resolve_type_proc
    end

    def filtered_possible_types=(new_filter_possible_types_proc)
      @filtered_possible_types_proc = new_filter_possible_types_proc
    end

    protected

    attr_reader :dirty_possible_types
  end
end
