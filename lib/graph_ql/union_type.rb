# A collection of {ObjectType}s
#
# @example a union of types
#   PetUnion = GraphQL::UnionType.new("Pet", "House pets", [DogType, CatType])
#
class GraphQL::UnionType
  include GraphQL::DefinitionHelpers::NonNullWithBang
  attr_reader :name, :description, :possible_types
  def initialize(name, desc, types)
    @name = name
    @description = desc
    @possible_types = types
  end

  def kind
    GraphQL::TypeKinds::UNION
  end

  # @see {InterfaceType#resolve_type}
  def resolve_type(object)
    type_name = object.class.name
    possible_types.find {|t| t.name == type_name}
  end
end
