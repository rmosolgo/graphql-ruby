---
layout: doc_stub
search: true
title: GraphQL::InputObjectType
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/InputObjectType
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/InputObjectType
---

Class: GraphQL::InputObjectType < GraphQL::BaseType
are key-value inputs for fields. 
Input objects have _arguments_ which are identical to
{GraphQL::Field arguments. They map names to types and support
default values. Their input types can be any input types, including
{InputObjectType}s. 
In a `resolve` function, you can access the values by making nested
lookups on `args`. 
Examples:
# An input type with name and number
PlayerInput = GraphQL::InputObjectType.define do
name("Player")
argument :name, !types.String
argument :number, !types.Int
end
# Accessing input values in a resolve function
resolve ->(obj, args, ctx) {
args[:player][:name]    # => "Tony Gwynn"
args[:player][:number]  # => 19
args[:player].to_h      # { "name" => "Tony Gwynn", "number" => 19 }
# ...
}
Instance methods:
coerce_non_null_input, coerce_result, initialize, initialize_copy,
kind, validate_non_null_input

