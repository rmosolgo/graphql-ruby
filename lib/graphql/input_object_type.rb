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
  attr_accessor :input_fields

  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    attr_definable :name, :description, :input_fields
    def initialize
      @input_fields = {}
    end

    def types
      GraphQL::DefinitionHelpers::TypeDefiner.instance
    end

    def input_field(name, type = nil, desc = nil, default_value: nil, &block)
      argument = if block_given?
        GraphQL::Argument.define(&block)
      else
        GraphQL::Argument.new
      end
      argument.name = name
      type && argument.type = type
      desc && argument.desc = desc
      default_value && argument.default_value = default_value
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

  def input_fields=(new_fields)
    @input_fields = GraphQL::DefinitionHelpers::StringNamedHash.new(new_fields).to_h
  end

  def kind
    GraphQL::TypeKinds::INPUT_OBJECT
  end
end
