# frozen_string_literal: true
module GraphQL
  # @api deprecated
  class ObjectType < GraphQL::BaseType
    extend Define::InstanceDefinable::DeprecatedDefine

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
      @clean_inherited_fields = nil
      @structural_interface_type_memberships = []
      @inherited_interface_type_memberships = []
    end

    def initialize_copy(other)
      super
      @structural_interface_type_memberships = other.structural_interface_type_memberships.dup
      @inherited_interface_type_memberships = other.inherited_interface_type_memberships.dup
      @fields = other.fields.dup
    end

    # This method declares interfaces for this type AND inherits any field definitions
    # @param new_interfaces [Array<GraphQL::Interface>] interfaces that this type implements
    # @deprecated Use `implements` instead of `interfaces`.
    def interfaces=(new_interfaces)
      @structural_interface_type_memberships = []
      @inherited_interface_type_memberships = []
      @clean_inherited_fields = nil
      implements(new_interfaces, inherit: true)
    end

    def interfaces(ctx = GraphQL::Query::NullContext)
      ensure_defined
      visible_ifaces = []
      unfiltered = ctx == GraphQL::Query::NullContext
      [@structural_interface_type_memberships, @inherited_interface_type_memberships].each do |tms|
        tms.each do |type_membership|
          if unfiltered || type_membership.visible?(ctx)
            # if this is derived from a class-based object, we have to
            # get the `.graphql_definition` of the attached interface.
            visible_ifaces << GraphQL::BaseType.resolve_related_type(type_membership.abstract_type)
          end
        end
      end

      visible_ifaces
    end

    def kind
      GraphQL::TypeKinds::OBJECT
    end

    # This fields doesnt have instrumenation applied
    # @see [Schema#get_field] Get field with instrumentation
    # @return [GraphQL::Field] The field definition for `field_name` (may be inherited from interfaces)
    def get_field(field_name)
      fields[field_name] || interface_fields[field_name]
    end

    # These fields don't have instrumenation applied
    # @see [Schema#get_fields] Get fields with instrumentation
    # @return [Array<GraphQL::Field>] All fields, including ones inherited from interfaces
    def all_fields
      interface_fields.merge(self.fields).values
    end

    # Declare that this object implements this interface.
    # This declaration will be validated when the schema is defined.
    # @param interfaces [Array<GraphQL::Interface>] add a new interface that this type implements
    # @param inherits [Boolean] If true, copy the interfaces' field definitions to this type
    def implements(interfaces, inherit: false, **options)
      if !interfaces.is_a?(Array)
        raise ArgumentError, "`implements(interfaces)` must be an array, not #{interfaces.class} (#{interfaces})"
      end
      @clean_inherited_fields = nil

      type_memberships = inherit ? @inherited_interface_type_memberships : @structural_interface_type_memberships
      interfaces.each do |iface|
        iface = BaseType.resolve_related_type(iface)
        if iface.is_a?(GraphQL::InterfaceType)
          type_memberships << iface.type_membership_class.new(iface, self, **options)
        end
      end
    end

    def resolve_type_proc
      nil
    end

    attr_writer :structural_interface_type_memberships

    protected

    attr_reader :structural_interface_type_memberships, :inherited_interface_type_memberships

    private

    def normalize_interfaces(ifaces)
      ifaces.map { |i_type| GraphQL::BaseType.resolve_related_type(i_type) }
    end

    def interface_fields
      if @clean_inherited_fields
        @clean_inherited_fields
      else
        ensure_defined
        @clean_inherited_fields = {}
        @inherited_interface_type_memberships.each do |type_membership|
          iface = GraphQL::BaseType.resolve_related_type(type_membership.abstract_type)
          if iface.is_a?(GraphQL::InterfaceType)
            @clean_inherited_fields.merge!(iface.fields)
          end
        end
        @clean_inherited_fields
      end
    end
  end
end
