# A collection of {ObjectType}s
#
# @example a union of types
#
#   PetUnion = GraphQL::UnionType.define do
#     name "Pet"
#     description "Animals that live in your house"
#     possible_types [DogType, CatType, FishType]
#   end
#
class GraphQL::UnionType
  include GraphQL::DefinitionHelpers::NonNullWithBang
  include GraphQL::DefinitionHelpers::DefinedByConfig
  attr_accessor :name, :description, :possible_types
  defined_by_config :name, :description, :possible_types

  def kind
    GraphQL::TypeKinds::UNION
  end

  # @see {InterfaceType#resolve_type}
  def resolve_type(object)
    type_name = object.class.name
    possible_types.find {|t| t.name == type_name}
  end
end
