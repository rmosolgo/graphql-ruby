# frozen_string_literal: true
module GraphQL
  # @api deprecated
  class UnionType < GraphQL::BaseType
    extend Define::InstanceDefinable::DeprecatedDefine

    # Rubocop was unhappy about the syntax when this was a proc literal
    class AcceptPossibleTypesDefinition
      def self.call(target, possible_types, options = {})
        target.add_possible_types(possible_types, **options)
      end
    end

    accepts_definitions :resolve_type, :type_membership_class,
      possible_types: AcceptPossibleTypesDefinition
    ensure_defined :possible_types, :resolve_type, :resolve_type_proc, :type_membership_class

    attr_accessor :resolve_type_proc
    attr_reader :type_memberships
    attr_accessor :type_membership_class

    def initialize
      super
      @type_membership_class = GraphQL::Schema::TypeMembership
      @type_memberships = []
      @cached_possible_types = nil
      @resolve_type_proc = nil
    end

    def initialize_copy(other)
      super
      @type_membership_class = other.type_membership_class
      @type_memberships = other.type_memberships.dup
      @cached_possible_types = nil
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
      if ctx == GraphQL::Query::NullContext
        # Only cache the default case; if we cached for every `ctx`, it would be a memory leak
        # (The warden should cache calls to this method, so it's called only once per query,
        # unless user code calls it directly.)
        @cached_possible_types ||= possible_types_for_context(ctx)
      else
        possible_types_for_context(ctx)
      end
    end

    def possible_types=(types)
      # This is a re-assignment, so clear the previous values
      @type_memberships = []
      @cached_possible_types = nil
      add_possible_types(types, **{})
    end

    def add_possible_types(types, **options)
      @type_memberships ||= []
      Array(types).each { |t|
        @type_memberships << self.type_membership_class.new(self, t, **options)
      }
      nil
    end

    # Get a possible type of this {UnionType} by type name
    # @param type_name [String]
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [GraphQL::ObjectType, nil] The type named `type_name` if it exists and is a member of this {UnionType}, (else `nil`)
    def get_possible_type(type_name, ctx)
      type = ctx.query.get_type(type_name)
      type if type && ctx.query.warden.possible_types(self).include?(type)
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

    def type_memberships=(type_memberships)
      @type_memberships = type_memberships
    end

    private

    def possible_types_for_context(ctx)
      visible_types = []
      @type_memberships.each do |type_membership|
        if type_membership.visible?(ctx)
          visible_types << BaseType.resolve_related_type(type_membership.object_type)
        end
      end
      visible_types
    end
  end
end
