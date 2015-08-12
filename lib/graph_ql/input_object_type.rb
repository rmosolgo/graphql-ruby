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

  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    attr_definable :name, :description, :input_fields
    def initialize
      @input_fields = {}
    end

    def types
      GraphQL::DefinitionHelpers::TypeDefiner.instance
    end

    def input_field(name, type = nil, desc = nil, &block)
      if block_given?
        argument = GraphQL::Argument.define(&block)
      else
        argument = GraphQL::Argument.new(
          name: name,
          type: type,
          description: desc
        )
      end
      @input_fields[name.to_s] = argument
    end

    def to_instance
      object = GraphQL::InputObjectType.new
      object.name = name
      object.description = description
      object.input_fields = @input_fields
      object
    end
  end

  # @overload input_fields(new_fields)
  #   Define allowed fields, normalized with {StringNamedHash}
  #   @param new_fields [Hash] allowed fields for this input object type
  #
  # @overload input_fields()
  #   Read the defined fields for this input type
  #   @return [Hash] allowed fields for this input object type
  #
  def input_fields(new_fields=nil)
    new_fields && self.input_fields = new_fields
    @input_fields
  end

  def input_fields=(new_fields)
    @input_fields = GraphQL::DefinitionHelpers::StringNamedHash.new(new_fields).to_h
  end

  def kind
    GraphQL::TypeKinds::INPUT_OBJECT
  end
end
