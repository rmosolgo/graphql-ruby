module GraphQL
  # A collection of types which implement the same fields
  #
  # @example An interface with three required fields
  #   DeviceInterface = GraphQL::InterfaceType.define do
  #     name("Device")
  #     description("Hardware devices for computing")
  #
  #     field :ram, types.String
  #     field :processor, ProcessorType
  #     field :release_year, types.Int
  #   end
  #
  class InterfaceType < GraphQL::BaseType
    include GraphQL::BaseType::HasPossibleTypes
    accepts_definitions :resolve_type, field: GraphQL::Define::AssignObjectField

    lazy_defined_attr_accessor :fields

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
