class GraphQL::ObjectType
  extend GraphQL::Definable
  attr_definable :name, :description, :interfaces
  include GraphQL::NonNullWithBang

  def initialize(&block)
    self.fields = []
    instance_eval(&block)
  end

  attr_accessor :fields
  def fields=(new_fields)
    stringified_fields = new_fields
      .reduce({}) { |memo, (key, value)| memo[key.to_s] = value; memo }
    @fields = stringified_fields
  end

  def field(type:, args: {}, desc: "")
    GraphQL::AccessField.new(type: type, arguments: args, description: desc)
  end

  def type
    @type ||= GraphQL::TypeDefiner.new
  end

  def kind
    GraphQL::TypeKinds::OBJECT
  end
end
