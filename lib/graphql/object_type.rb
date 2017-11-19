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
    accepts_definitions :interfaces, :fields, :mutation, field: GraphQL::Define::AssignObjectField
    accepts_definitions implements: ->(type, *interfaces, inherit: false) { type.implements(interfaces, inherit: inherit) }

    attr_accessor :fields, :mutation
    ensure_defined(:fields, :mutation, :interfaces)

    # @!attribute fields
    #   @return [Hash<String => GraphQL::Field>] Map String fieldnames to their {GraphQL::Field} implementations

    # @!attribute mutation
    #   @return [GraphQL::Relay::Mutation, nil] The mutation this field was derived from, if it was derived from a mutation

    def initialize
      super
      @fields = {}
      @interface_fields = {}
      @dirty_interfaces = []
      @dirty_inherited_interfaces = []
    end

    def initialize_copy(other)
      super
      @clean_interfaces = nil
      @clean_inherited_interfaces = nil
      @dirty_interfaces = other.dirty_interfaces.dup
      @dirty_inherited_interfaces = other.dirty_inherited_interfaces.dup
      @fields = other.fields.dup
    end

    # This method declares interfaces for this type AND inherits any field definitions
    # @param new_interfaces [Array<GraphQL::Interface>] interfaces that this type implements
    # @deprecated Use `implements` instead of `interfaces`.
    def interfaces=(new_interfaces)
      @clean_interfaces = nil
      @clean_inherited_interfaces = nil
      @clean_inherited_fields = nil

      @dirty_inherited_interfaces = []
      @dirty_inherited_fields = {}
      implements(new_interfaces, inherit: true)
    end

    def interfaces
      load_interfaces
      @clean_interfaces
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
    def implements(interfaces, inherit: false)
      if !interfaces.is_a?(Array)
        raise ArgumentError, "`implements(interfaces)` must be an array, not #{interfaces.class} (#{interfaces})"
      end

      @clean_interfaces = nil
      @clean_inherited_fields = nil
      dirty_ifaces = inherit ? @dirty_inherited_interfaces : @dirty_interfaces
      dirty_ifaces.concat(interfaces)
    end

    def name=(name)
      GraphQL::NameValidator.validate!(name)
      @name = name
    end

    def to_ast_node
      @ast_node ||= begin
        GraphQL::Language::Nodes::ObjectTypeDefinition.new(
          name: name,
          interfaces: interfaces.map(&:to_ast_type_name_node),
          fields: fields.values.map(&:to_ast_node),
          description: description,
        )
      end
    end

    protected

    attr_reader :dirty_interfaces, :dirty_inherited_interfaces

    private

    def normalize_interfaces(ifaces)
      ifaces.map { |i_type| GraphQL::BaseType.resolve_related_type(i_type) }
    end

    def interface_fields
      load_interfaces
      @clean_inherited_fields
    end

    def load_interfaces
      @clean_interfaces ||= begin
        ensure_defined
        clean_ifaces = normalize_interfaces(@dirty_interfaces)
        clean_inherited_ifaces = normalize_interfaces(@dirty_inherited_interfaces)
        inherited_fields = {}
        clean_inherited_ifaces.each do |iface|
          # This will be found later in schema validation:
          if iface.is_a?(GraphQL::InterfaceType)
            inherited_fields.merge!(iface.fields)
          end
        end
        @clean_inherited_fields = inherited_fields
        clean_inherited_ifaces + clean_ifaces
      end
    end
  end
end
