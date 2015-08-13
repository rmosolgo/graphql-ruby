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
  extend GraphQL::DefinitionHelpers::Definable
  include GraphQL::DefinitionHelpers::DefinedByConfig
  attr_definable :name, :description, :interfaces, :fields

  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    attr_definable :name, :description, :interfaces
    def initialize
      @interfaces = []
      @fields = {}
    end

    def types
      GraphQL::DefinitionHelpers::TypeDefiner.instance
    end

    def field(name_or_pair, type = nil, desc = nil, field: nil, property: nil, &block)
      if name_or_pair.is_a?(Hash)
        name = name_or_pair.keys.first
        value = name_or_pair[name]
        if value.is_a?(GraphQL::Field)
          field = value
        else
          property = value
        end
      else
        name = name_or_pair
      end
      field ||= GraphQL::Field.define(&block)
      type && field.type = type
      desc && field.description = desc
      property && field.resolve = -> (t,a,c) { t.public_send(property)}
      field.name ||= name.to_s
      @fields[name.to_s] = field
    end

    def type_class
      GraphQL::ObjectType
    end

    def to_instance
      object = type_class.new
      object.name = name
      object.description = description
      object.fields = @fields
      object.interfaces = interfaces
      object
    end
  end

  def initialize(&block)
    self.fields = {}
    self.interfaces = []
  end

  # @overload fields(new_fields)
  #   @deprecated use {.define} API instead
  #   Define `new_fields` as the fields this type exposes, uses {#fields=}
  #
  # @overload fields()
  #   @return [Hash] fields this type exposes
  def fields(new_fields=nil)
    if !new_fields.nil?
      self.fields = new_fields
    end
    @fields
  end


  # Define fields to be `new_fields`, normalize with {StringNamedHash}
  # @param new_fields [Hash] The fields exposed by this type
  def fields=(new_fields)
    @fields = GraphQL::DefinitionHelpers::StringNamedHash.new(new_fields).to_h
  end

  # @overload interfaces(new_interfaces)
  #   @deprecated use {.define} API instead
  #   Declare that this type implements `new_interfaces`.
  #
  #   @param new_interfaces [Array<GraphQL::Interface>] interfaces that this type implements
  #
  # @overload interfaces
  #   @return [Array<GraphQL::Interface>] interfaces that this type implements
  #
  def interfaces(new_interfaces=nil)
    if !new_interfaces.nil?
      self.interfaces = new_interfaces
    end
    @interfaces
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
