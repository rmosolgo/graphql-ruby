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
class GraphQL::InterfaceType < GraphQL::BaseType
  defined_by_config :name, :description, :fields, :resolve_type
  attr_accessor :name, :description, :fields, :resolve_type

  # The default implementation of {#resolve_type} gets `object.class.name`
  # and finds a type with the same name
  DEFAULT_RESOLVE_TYPE = -> (object) {
    type_name = object.class.name
    possible_types.find {|t| t.name == type_name}
  }

  def kind
    GraphQL::TypeKinds::INTERFACE
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
    instance_exec(object, &@resolve_type_proc)
  end

  def resolve_type=(new_proc)
    @resolve_type_proc = new_proc || DEFAULT_RESOLVE_TYPE
  end
end
