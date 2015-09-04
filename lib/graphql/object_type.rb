# This type exposes fields on an object.
#
#  @example defining a type for your IMDB clone
#    MovieType = GraphQL::ObjectType.define do
#      name "Movie"
#      description "A full-length film or a short film"
#      interfaces [ProductionInterface, DurationInterface]
#
#      field :runtimeMinutes, !types.Int, property: :runtime_minutes
#      field :director, PersonType
#      field :cast, CastType
#      field :starring, types[PersonType] do
#        arguments :limit, types.Int
#        resolve -> (object, args, ctx) {
#          stars = object.cast.stars
#          args[:limit] && stars = stars.limit(args[:limit])
#          stars
#        }
#       end
#    end
#
class GraphQL::ObjectType < GraphQL::BaseType
  defined_by_config :name, :description, :interfaces, :fields
  attr_accessor :name, :description, :interfaces, :fields

  # Define fields to be `new_fields`, normalize with {StringNamedHash}
  # @param new_fields [Hash] The fields exposed by this type
  def fields=(new_fields)
    @fields = GraphQL::DefinitionHelpers::StringNamedHash.new(new_fields).to_h
  end

  #   Shovel this type into each interface's `possible_types` array.
  #
  #   (There's a bug here: if you define interfaces twice, it won't remove previous definitions.)
  #   @param new_interfaces [Array<GraphQL::Interface>] interfaces that this type implements
  def interfaces=(new_interfaces)
    new_interfaces.each {|i| i.possible_types << self }
    @interfaces = new_interfaces
  end

  def kind
    GraphQL::TypeKinds::OBJECT
  end
end
