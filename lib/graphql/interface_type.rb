# frozen_string_literal: true
module GraphQL
  # An Interface contains a collection of types which implement some of the same fields.
  #
  # Interfaces can have fields, defined with `field`, just like an object type.
  #
  # Objects which implement this field _inherit_ field definitions from the interface.
  # An object type can override the inherited definition by redefining that field.
  #
  # @example An interface with three fields
  #   DeviceInterface = GraphQL::InterfaceType.define do
  #     name("Device")
  #     description("Hardware devices for computing")
  #
  #     field :ram, types.String
  #     field :processor, ProcessorType
  #     field :release_year, types.Int
  #   end
  #
  # @example Implementing an interface with an object type
  #   Laptoptype = GraphQL::ObjectType.define do
  #     interfaces [DeviceInterface]
  #   end
  #
  class InterfaceType < GraphQL::BaseType
    accepts_definitions :fields, :orphan_types, :resolve_type, field: GraphQL::Define::AssignObjectField

    attr_accessor :fields, :orphan_types, :resolve_type_proc
    ensure_defined :fields, :orphan_types, :resolve_type_proc, :resolve_type

    def initialize
      super
      @fields = {}
      @orphan_types = []
      @resolve_type_proc = nil
    end

    def initialize_copy(other)
      super
      @fields = other.fields.dup
      @orphan_types = other.orphan_types.dup
    end

    def kind
      GraphQL::TypeKinds::INTERFACE
    end

    def resolve_type(value, ctx)
      ctx.query.resolve_type(self, value)
    end

    def resolve_type=(resolve_type_callable)
      @resolve_type_proc = resolve_type_callable
    end

    # @return [GraphQL::Field] The defined field for `field_name`
    def get_field(field_name)
      fields[field_name]
    end

    # These fields don't have instrumenation applied
    # @see [Schema#get_fields] Get fields with instrumentation
    # @return [Array<GraphQL::Field>] All fields on this type
    def all_fields
      fields.values
    end

    # Get a possible type of this {InterfaceType} by type name
    # @param type_name [String]
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [GraphQL::ObjectType, nil] The type named `type_name` if it exists and implements this {InterfaceType}, (else `nil`)
    def get_possible_type(type_name, ctx)
      type = ctx.query.get_type(type_name)
      type if type && ctx.query.schema.possible_types(self).include?(type)
    end

    # Check if a type is a possible type of this {InterfaceType}
    # @param type [String, GraphQL::BaseType] Name of the type or a type definition
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [Boolean] True if the `type` exists and is a member of this {InterfaceType}, (else `nil`)
    def possible_type?(type, ctx)
      type_name = type.is_a?(String) ? type : type.graphql_name
      !get_possible_type(type_name, ctx).nil?
    end
  end
end
