class GraphQL::ObjectType
  extend GraphQL::Definable
  attr_definable :name, :description, :interfaces, :fields
  include GraphQL::NonNullWithBang

  def initialize(&block)
    self.fields = []
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
    @fields = stringified_fields
  end

  def field(type:, args: {}, property: nil, desc: "", deprecation_reason: nil)
    GraphQL::AccessField.new(type: type, arguments: args, property: property, description: desc, deprecation_reason: deprecation_reason)
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
