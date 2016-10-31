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
    accepts_definitions :fields, field: GraphQL::Define::AssignObjectField

    lazy_methods do
      attr_accessor :fields
    end

    def initialize
      @fields = {}
    end

    def kind
      GraphQL::TypeKinds::INTERFACE
    end

    # @return [GraphQL::Field] The defined field for `field_name`
    def get_field(field_name)
      fields[field_name]
    end

    # @return [Array<GraphQL::Field>] All fields on this type
    def all_fields
      fields.values
    end
  end
end
