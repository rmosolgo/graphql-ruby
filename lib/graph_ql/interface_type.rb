# A collection of types which implement the same fields
#
# @example An interface with three required fields
#   DeviceInterface = GraphQL::InterfaceType.new do |i, types, fields|
#     i.name("Device")
#     i.description("Hardware devices for computing")
#     i.fields({
#       ram:          fields.build(type: types.String),
#       processor:    fields.build(type: ProcessorType),
#       release_year: fields.build(type: types.Int),
#     })
#   end
#
class GraphQL::InterfaceType < GraphQL::ObjectType
  def kind
    GraphQL::TypeKinds::INTERFACE
  end

  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    attr_definable :name, :description

    def initialize
      @fields = {}
    end

    def types
      GraphQL::DefinitionHelpers::TypeDefiner.instance
    end

    def field(name_or_pair, type = nil, desc = nil, &block)
      if name_or_pair.is_a?(Hash)
        name = name_or_pair.keys.first
        value = name_or_pair[name]
        if value.is_a?(GraphQL::Field)
          field = value
        end
      else
        name = name_or_pair
      end
      field ||= GraphQL::Field.define(&block)
      type && field.type = type
      desc && field.description = desc
      field.name ||= name.to_s
      @fields[name.to_s] = field
    end

    def to_instance
      object = GraphQL::InterfaceType.new
      object.name = name
      object.description = description
      object.fields = @fields
      object
    end
  end

  # @return [Array<GraphQL::ObjectType>] Types which declare that they implement this interface
  def possible_types
    @possible_types ||= []
  end

  # Return the implementing type for `object`.
  # The default implementation assumes that there's a type with the same name as `object.class.name`.
  # Maybe you'll need to override this in your own interfaces!
  #
  # @param object [Object] the object which needs a type to expose it
  # @return [GraphQL::ObjectType] the type which should expose `object`
  def resolve_type(object)
    @possible_types.find {|t| t.name == object.class.name }
  end
end
