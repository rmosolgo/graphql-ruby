class GraphQL::InputObjectType < GraphQL::ObjectType
  attr_definable :input_fields

  def input_fields(new_fields=nil)
    if new_fields.nil?
      @new_fields
    else
      @new_fields = new_fields
        .reduce({}) {|memo, (k, v)| memo[k.to_s] = v; memo}
        .each { |k, v| v.respond_to?("name=") && v.name = k}
    end
  end

  def kind
    GraphQL::TypeKinds::INPUT_OBJECT
  end

  def to_s
    "<GraphQL::InputObjectType #{name}>"
  end
end
