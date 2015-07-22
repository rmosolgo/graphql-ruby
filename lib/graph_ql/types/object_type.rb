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
    "<GraphQL::ObjectType #{name}>"
  end

  def inspect
    to_s
  end
end
