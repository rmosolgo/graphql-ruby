---
layout: doc_stub
search: true
title: GraphQL::Relay::Mutation
url: http://www.rubydoc.info/gems/graphql/GraphQL/Relay/Mutation
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Relay/Mutation
---

Class: GraphQL::Relay::Mutation < Object
Define a Relay mutation:
- give it a name (used for derived inputs & outputs)
- declare its inputs
- declare its outputs
- declare the mutation procedure
`resolve` should return a hash with a key for each of the
`return_field`s 
Inputs may also contain a `clientMutationId` 
Examples:
# Updating the name of an item
UpdateNameMutation = GraphQL::Relay::Mutation.define do
name "UpdateName"
input_field :name, !types.String
input_field :itemId, !types.ID
return_field :item, ItemType
resolve ->(inputs, ctx) {
item = Item.find_by_id(inputs[:id])
item.update(name: inputs[:name])
{item: item}
}
end
MutationType = GraphQL::ObjectType.define do
# The mutation object exposes a field:
field :updateName, field: UpdateNameMutation.field
end
# Then query it:
query_string = %|
mutation updateName {
updateName(input: {itemId: 1, name: "new name", clientMutationId: "1234"}) {
item { name }
clientMutationId
}|
GraphQL::Query.new(MySchema, query_string).result
# {"data" => {
#   "updateName" => {
#     "item" => { "name" => "new name"},
#     "clientMutationId" => "1234"
#   }
# }}
# Using a GraphQL::Function
class UpdateAttributes < GraphQL::Function
attr_reader :model, :return_as, :arguments
def initialize(model:, return_as:, attributes:)
@model = model
@arguments = {}
attributes.each do |name, type|
arg_name = name.to_s
@arguments[arg_name] = GraphQL::Argument.define(name: arg_name, type: type)
end
@arguments["id"] = GraphQL::Argument.define(name: "id", type: !GraphQL::ID_TYPE)
@return_as = return_as
@attributes = attributes
end
def type
fn = self
GraphQL::ObjectType.define do
name "Update#{fn.model.name}AttributesResponse"
field :clientMutationId, types.ID
field fn.return_as.keys[0], fn.return_as.values[0]
end
end
def call(obj, args, ctx)
record = @model.find(args[:inputs][:id])
new_values = {}
@attributes.each { |a| new_values[a] = args[a] }
record.update(new_values)
{ @return_as => record }
end
end
UpdateNameMutation = GraphQL::Relay::Mutation.define do
name "UpdateName"
function UpdateAttributes.new(model: Item, return_as: { item: ItemType }, attributes: {name: !types.String})
end
Includes:
GraphQL::Define::InstanceDefinable
Instance methods:
field, get_arity, has_generated_return_type?, initialize,
input_type, resolve=, result_class

