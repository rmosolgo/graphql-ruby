---
layout: doc_stub
search: true
title: GraphQL::Field
url: http://www.rubydoc.info/gems/graphql/GraphQL/Field
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Field
---

Class: GraphQL::Field < Object
{Field}s belong to {ObjectType}s and  They're usually created with
the `field` helper. If you create it by hand, make sure {#name is a
String. 
A field must have a return type, but if you want to defer the return
type calculation until later, you can pass a proc for the return
type. That proc will be called when the schema is defined. 
For complex field definition, you can pass a block to the `field`
helper, eg `field :name do ... end`. This block is equivalent to
calling `GraphQL::Field.define { ... }`. 
## Resolve 
Fields have `resolve` functions to determine their values at
query-time. The default implementation is to call a method on the
object based on the field name. 
You can specify a custom proc with the `resolve` helper. 
There are some shortcuts for common `resolve` implementations:
- Provide `property:` to call a method with a different name than
the field name
- Provide `hash_key:` to resolve the field by doing a key lookup,
eg `obj[:my_hash_key]`
## Arguments 
Fields can take inputs; they're called arguments. You can define
them with the `argument` helper. 
They can have default values which will be provided to `resolve` if
the query doesn't include a value. 
Only certain types maybe used for inputs: 
- Scalars - Enums - Input Objects - Lists of those types 
Input types may also be non-null   in that case, the query will
fail if the input is not present. 
## Complexity 
Fields can have _complexity_ values which describe the computation
cost of resolving the field. You can provide the complexity as a
constant with `complexity:` or as a proc, with the `complexity`
helper. 
Examples:
# Lazy type resolution
# If the field's type isn't defined yet, you can pass a proc
field :city, -> { TypeForModelName.find("City") }
# Defining a field with a block
field :city, CityType do
# field definition continues inside the block
end
# Create a field which calls a method with the same name.
GraphQL::ObjectType.define do
field :name, types.String, "The name of this thing "
end
# Create a field that calls a different method on the object
GraphQL::ObjectType.define do
# use the `property` keyword:
field :firstName, types.String, property: :first_name
end
# Create a field looks up with `[hash_key]`
GraphQL::ObjectType.define do
# use the `hash_key` keyword:
field :firstName, types.String, hash_key: :first_name
end
# Create a field with an argument
field :students, types[StudentType] do
argument :grade, types.Int
resolve ->(obj, args, ctx) {
Student.where(grade: args[:grade])
}
end
# Argument with a default value
field :events, types[EventType] do
# by default, don't include past events
argument :includePast, types.Boolean, default_value: false
resolve ->(obj, args, ctx) {
args[:includePast] # => false if no value was provided in the query
# ...
}
end
# Custom complexity values
# Complexity can be a number or a proc.
# Complexity can be defined with a keyword:
field :expensive_calculation, !types.Int, complexity: 10
# Or inside the block:
field :expensive_calculation_2, !types.Int do
complexity ->(ctx, args, child_complexity) { ctx[:current_user].staff? ? 0 : 10 }
end
# Calculating the complexity of a list field
field :items, types[ItemType] do
argument :limit, !types.Int
# Mulitply the child complexity by the possible items on the list
complexity ->(ctx, args, child_complexity) { child_complexity * args[:limit] }
end
# Creating a field, then assigning it to a type
name_field = GraphQL::Field.define do
name("Name")
type(!types.String)
description("The name of this thing")
resolve ->(object, arguments, context) { object.name }
end
NamedType = GraphQL::ObjectType.define do
# The second argument may be a GraphQL::Field
field :name, name_field
end
Includes:
GraphQL::Define::InstanceDefinable
Instance methods:
build_default_resolver, connection?, default_arguments, initialize,
initialize_copy, lazy_resolve, lazy_resolve=, prepare_lazy, resolve,
resolve=, to_s, type, type=

