# This type exposes fields on an object.
#
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

    def field(name_or_pair, type = nil, desc = nil, &block)
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

    def to_instance
      object = GraphQL::ObjectType.new
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
    if block_given?
      yield(
        self,
        GraphQL::DefinitionHelpers::TypeDefiner.instance,
        GraphQL::DefinitionHelpers::FieldDefiner.instance,
        GraphQL::DefinitionHelpers::ArgumentDefiner.instance
      )
      warn("Initializing with .new is deprecated, use .define instead! (see #{self})")
    end
  end

  # @overload fields(new_fields)
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
  #   Declare that this type implements `new_interfaces`.
  #   Shovel this type into each interface's `possible_types` array.
  #
  #   (There's a bug here: if you define interfaces twice, it won't remove previous definitions.)
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
