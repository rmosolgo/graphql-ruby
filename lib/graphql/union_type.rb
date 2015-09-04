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
class GraphQL::UnionType < GraphQL::BaseType
  attr_accessor :name, :description, :possible_types, :resolve_type
  defined_by_config :name, :description, :possible_types, :resolve_type

  def kind
    GraphQL::TypeKinds::UNION
  end

  # @see {InterfaceType#resolve_type}
  def resolve_type(object)
    instance_exec(object, &@resolve_type_proc)
  end

  def resolve_type=(new_proc)
    @resolve_type_proc = new_proc || GraphQL::InterfaceType::DEFAULT_RESOLVE_TYPE
  end
end
