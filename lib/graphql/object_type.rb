# frozen_string_literal: true
module GraphQL
  # This type exposes fields on an object.
  #
  # @example defining a type for your IMDB clone
  #   MovieType = GraphQL::ObjectType.define do
  #     name "Movie"
  #     description "A full-length film or a short film"
  #     interfaces [ProductionInterface, DurationInterface]
  #
  #     field :runtimeMinutes, !types.Int, property: :runtime_minutes
  #     field :director, PersonType
  #     field :cast, CastType
  #     field :starring, types[PersonType] do
  #       argument :limit, types.Int
  #       resolve ->(object, args, ctx) {
  #         stars = object.cast.stars
  #         args[:limit] && stars = stars.limit(args[:limit])
  #         stars
  #       }
  #      end
  #   end
  #
  class ObjectType < GraphQL::BaseType
    accepts_definitions :interfaces, :fields, :mutation, :relay_node_type, field: GraphQL::Define::AssignObjectField
    accepts_definitions implements: ->(type, *interfaces, inherit: false) { type.implements(interfaces, inherit: inherit) }

    attr_accessor :fields, :mutation, :relay_node_type
    ensure_defined(:fields, :mutation, :interfaces, :relay_node_type)

    # @!attribute fields
    #   @return [Hash<String => GraphQL::Field>] Map String fieldnames to their {GraphQL::Field} implementations

    # @!attribute mutation
    #   @return [GraphQL::Relay::Mutation, nil] The mutation this object type was derived from, if it is an auto-generated payload type.

    def initialize
      super
      @fields = {}
      @interface_fields = {}
      @interface_type_memberships = []
      @inherited_interface_type_memberships = []
    end

    def initialize_copy(other)
      super
      @interface_type_memberships = other.interface_type_memberships.dup
      @inherited_interface_type_memberships = other.inherited_interface_type_memberships.dup
      @fields = other.fields.dup
    end

    # This method declares interfaces for this type AND inherits any field definitions
    # @param new_interfaces [Array<GraphQL::Interface>] interfaces that this type implements
    # @deprecated Use `implements` instead of `interfaces`.
    def interfaces=(new_interfaces)
      @interface_type_memberships = []
      @inherited_interface_type_memberships = []
      @dirty_inherited_fields = {}
      implements(new_interfaces, inherit: true)
    end

    def interfaces(ctx = GraphQL::Query::NullContext)
      load_interfaces(ctx)
    end

    def kind
      GraphQL::TypeKinds::OBJECT
    end

    # This fields doesnt have instrumenation applied
    # @see [Schema#get_field] Get field with instrumentation
    # @return [GraphQL::Field] The field definition for `field_name` (may be inherited from interfaces)
    def get_field(field_name, ctx = GraphQL::Query::NullContext)
      fields[field_name] || interface_fields(ctx)[field_name]
    end

    # These fields don't have instrumenation applied
    # @see [Schema#get_fields] Get fields with instrumentation
    # @return [Array<GraphQL::Field>] All fields, including ones inherited from interfaces
    def all_fields(ctx = GraphQL::Query::NullContext)
      interface_fields(ctx).merge(self.fields).values
    end

    # Declare that this object implements this interface.
    # This declaration will be validated when the schema is defined.
    # @param interfaces [Array<GraphQL::Interface>] add a new interface that this type implements
    # @param inherits [Boolean] If true, copy the interfaces' field definitions to this type
    def implements(interfaces, inherit: false, **options)
      if !interfaces.is_a?(Array)
        raise ArgumentError, "`implements(interfaces)` must be an array, not #{interfaces.class} (#{interfaces})"
      end

      type_memberships = inherit ? @inherited_interface_type_memberships : @interface_type_memberships
      type_memberships_from_interfaces = interfaces.map do |iface|
        iface.type_membership_class.new(iface, self, options)
      end
      type_memberships.concat(type_memberships_from_interfaces)
    end

    def resolve_type_proc
      nil
    end

    def interface_type_memberships=(interface_type_memberships)
      @interface_type_memberships = interface_type_memberships
    end

    protected

    attr_reader :interface_type_memberships, :inherited_interface_type_memberships

    private

    def normalize_interfaces(ifaces)
      ifaces.map { |i_type| GraphQL::BaseType.resolve_related_type(i_type) }
    end

    def interface_fields(ctx = GraphQL::Query::NullContext)
      load_interfaces(ctx)
      @clean_inherited_fields
    end

    def load_interfaces(ctx)
      if ctx == GraphQL::Query::NullContext
        @cached_interfaces ||= interfaces_for_context(ctx)
      else
        interfaces_for_context(ctx)
      end
    end

    def interfaces_for_context(ctx)
      ensure_defined
      clean_ifaces = []
      clean_inherited_ifaces = []
      inherited_fields = {}
      @interface_type_memberships.each do |type_membership|
        if type_membership.visible?(ctx)
          clean_ifaces << GraphQL::BaseType.resolve_related_type(type_membership.abstract_type)
        end
      end

      @inherited_interface_type_memberships.each do |type_membership|
        if type_membership.visible?(ctx)
          iface = GraphQL::BaseType.resolve_related_type(type_membership.abstract_type)
          clean_inherited_ifaces << iface 
          if iface.is_a?(GraphQL::InterfaceType)
            inherited_fields.merge!(iface.fields)
          end
        end
      end

      @clean_inherited_fields = inherited_fields
      clean_inherited_ifaces + clean_ifaces
    end
  end
end
