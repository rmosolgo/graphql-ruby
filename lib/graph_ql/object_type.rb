class GraphQL::ObjectType
  extend GraphQL::Definable
  attr_definable :name, :description, :interfaces

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

  def field(type=nil, property=nil, desc=nil)
    @access_field_definer ||= GraphQL::AccessFieldDefiner.new
    if !type.nil?
      @access_field_definer.of_type(type, property, desc)
    else
      @access_field_definer
    end
  end

  def kind
    GraphQL::TypeKinds::OBJECT
  end
end
