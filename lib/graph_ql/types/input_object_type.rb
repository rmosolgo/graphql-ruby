# A complex input type for a field argument.
#
# @example An input type with name and number
#   PlayerInput = GraphQL::InputObjectType.new do |i, types, fields, args|
#     i.name("Player")
#     i.input_fields({
#       name: args.build(type: !types.String)
#       number: args.build(type: !types.Int)
#     })
#   end
#
class GraphQL::InputObjectType < GraphQL::ObjectType
  attr_definable :input_fields

  # @overload input_fields(new_fields)
  #   Define allowed fields, normalized with {StringNamedHash}
  #   @param new_fields [Hash] allowed fields for this input object type
  #
  # @overload input_fields()
  #   Read the defined fields for this input type
  #   @return [Hash] allowed fields for this input object type
  #
  def input_fields(new_fields=nil)
    if !new_fields.nil?
      @new_fields = GraphQL::StringNamedHash.new(new_fields).to_h
    end
    @new_fields
  end

  def kind
    GraphQL::TypeKinds::INPUT_OBJECT
  end
end
