class GraphQL::InputObjectType < GraphQL::ObjectType
  attr_definable :input_fields

  def input_fields(new_fields=nil)
    if !new_fields.nil?
      @new_fields = GraphQL::StringNamedHash.new(new_fields).to_h
    end
    @new_fields
  end

  def kind
    GraphQL::TypeKinds::INPUT_OBJECT
  end

  def to_s
    "<GraphQL::InputObjectType #{name}>"
  end
end
