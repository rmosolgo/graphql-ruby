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
class GraphQL::ObjectType
  include GraphQL::DefinitionHelpers::NonNullWithBang
  include GraphQL::DefinitionHelpers::DefinedByConfig
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

  # Print the human-readable name of this type
  def to_s
    Printer.instance.print(self)
  end

  alias :inspect :to_s

  # @param other [GraphQL::ObjectType] compare to this object
  # @return [Boolean] are these types equivalent? (incl. non-null, list)
  def ==(other)
    if other.is_a?(GraphQL::ObjectType)
      self.to_s == other.to_s
    else
      super
    end
  end

  # Print a type, using the query-style naming pattern
  class Printer
    include Singleton
    def print(type)
      if type.kind.non_null?
        "#{print(type.of_type)}!"
      elsif type.kind.list?
        "[#{print(type.of_type)}]"
      else
        type.name
      end
    end
  end
end
