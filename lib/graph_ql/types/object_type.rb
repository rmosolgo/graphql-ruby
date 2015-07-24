class GraphQL::ObjectType
  extend GraphQL::Definable
  attr_definable :name, :description, :interfaces, :fields
  include GraphQL::NonNullWithBang

  def initialize(&block)
    self.fields = []
    self.interfaces = []
    yield(self, GraphQL::TypeDefiner.instance, GraphQL::FieldDefiner.instance, GraphQL::ArgumentDefiner.instance)
  end

  def fields(new_fields=nil)
    if !new_fields.nil?
      self.fields = new_fields
    end
    @fields
  end

  def fields=(new_fields)
    stringified_fields = GraphQL::StringNamedHash.new(new_fields).to_h
    # TODO: should this field be exposed during introspection? https://github.com/graphql/graphql-js/issues/73
    stringified_fields["__typename"] = GraphQL::Introspection::TypenameField.create(self)
    @fields = stringified_fields
  end

  def interfaces(new_interfaces=nil)
    if !new_interfaces.nil?
      # if you define interfaces twice, you're gonna have a bad time :(
      # (because it gets registered with that interface, then overriden)
      @interfaces = new_interfaces
      new_interfaces.each {|i| i.possible_types << self }
    end
    @interfaces
  end

  def kind
    GraphQL::TypeKinds::OBJECT
  end

  def to_s
    Printer.instance.print(self)
  end

  alias :inspect :to_s

  def ==(other)
    if other.is_a?(GraphQL::ObjectType)
      self.to_s == other.to_s
    else
      super
    end
  end

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
