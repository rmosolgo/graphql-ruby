class GraphQL::ObjectType
  extend GraphQL::Definable
  attr_definable :name, :description, :interfaces, :fields
  include GraphQL::NonNullWithBang

  def initialize(&block)
    self.fields = []
    self.interfaces = []
    instance_eval(&block)
  end

  def fields(new_fields=nil)
    if new_fields
      self.fields = new_fields
    else
      @fields
    end
  end

  def fields=(new_fields)
    stringified_fields = new_fields
      .reduce({}) { |memo, (key, value)| memo[key.to_s] = value; memo }
    # Set the name from its context on this type:
    stringified_fields.each {|k, v| v.respond_to?("name=") && v.name = k }
    stringified_fields["__typename"] = GraphQL::Field.new do |f|
      f.name "__typename"
      f.description "The name of this type"
      f.type -> { !GraphQL::STRING_TYPE }
      f.resolve -> (o, a, c) { self.name }
    end
    @fields = stringified_fields
  end

  def field(type:, args: {}, property: nil, desc: "", deprecation_reason: nil)
    resolve = if property.nil?
      -> (o, a, c)  { GraphQL::Query::DEFAULT_RESOLVE }
    else
      -> (object, a, c) { object.send(property) }
    end

    GraphQL::Field.new do |f|
      f.type(type)
      f.arguments(args)
      f.description(desc)
      f.resolve(resolve)
      f.deprecation_reason(deprecation_reason)
    end
  end

  def arg(type:, desc: "", default_value: nil)
    GraphQL::InputValue.new(type: type, description: desc, default_value: default_value)
  end

  def type
    @type ||= GraphQL::TypeDefiner.new
  end

  def interfaces(new_interfaces=nil)
    if new_interfaces.nil?
      @interfaces
    else
      @interfaces = new_interfaces
      new_interfaces.each {|i| i.possible_types << self }
    end
  end

  def kind
    GraphQL::TypeKinds::OBJECT
  end

  def to_s
    name
  end
end
