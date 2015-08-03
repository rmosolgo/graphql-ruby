# Some conveniences for definining return & argument types.
#
# Passed into initialization blocks, eg {ObjectType#initialize}, {Field#initialize}
class GraphQL::DefinitionHelpers::TypeDefiner
  include Singleton

  def Int;      GraphQL::INT_TYPE;      end
  def String;   GraphQL::STRING_TYPE;   end
  def Float;    GraphQL::FLOAT_TYPE;    end
  def Boolean;  GraphQL::BOOLEAN_TYPE;  end
  def ID;       GraphQL::ID_TYPE;       end

  # Make a {ListType} which wraps the input type
  #
  # @example making a list type
  #   list_of_strings = types[types.String]
  #   list_of_strings.inspect
  #   # => "[String]"
  #
  # @param type [Type] A type to be wrapped in a ListType
  # @return [GraphQL::ListType] A ListType wrapping `type`
  def [](type)
    GraphQL::ListType.new(of_type: type)
  end
end
