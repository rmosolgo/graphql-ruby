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

    attr_accessor :resolve_type_proc
    attr_reader :type_visibilities

    class << self
      def possible_types(*types, visibility: nil)
        type_visibilities << @type_visibility_class.new(types, visibility)
      end

      def type_visibility_class(visibility_class = nil)
        if visibility_class
          @type_visibility_class = visibility_class
        else
          @type_visibility_class || GraphQL::Schema::TypeMembership
        end
      end

      def type_visibilities
        @type_visibilities ||= []
      end
    end

    def initialize
      super
      @type_visibilities = self.class.type_visibilities
      @cached_possible_types = {}
      @resolve_type_proc = nil
    end

    def initialize_copy(other)
      super
      @type_visibilities = other.type_visibilities.dup
      @cached_possible_types = {}
    end

    def kind
      GraphQL::TypeKinds::UNION
    end

    # @return [Boolean] True if `child_type_defn` is a member of this {UnionType}
    def include?(child_type_defn, ctx = GraphQL::Query::NullContext)
      possible_types(ctx).include?(child_type_defn)
    end

    # @return [Array<GraphQL::ObjectType>] Types which may be found in this union
    def possible_types(ctx = GraphQL::Query::NullContext)
      @cached_possible_types[ctx] ||= begin
        @type_visibilities.reduce([]) do |types, type_visibility|
          selected_types = type_visibility.visible?(ctx) ? types + type_visibility.types : types
          selected_types.map { |type| GraphQL::BaseType.resolve_related_type(type) }
        end
      end
    end

    def possible_types=(types, visibility: nil)
      @type_visibilities = [self.class.type_visibility_class.new(types, visibility)]
      @cached_possible_types = {}
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

    def resolve_type(value, ctx)
      ctx.query.resolve_type(self, value)
    end

    def resolve_type=(new_resolve_type_proc)
      @resolve_type_proc = new_resolve_type_proc
    end

    def type_visibilities=(type_visibilities)
      @cached_possible_types = {}
      @type_visibilities = type_visibilities
    end
  end
end
