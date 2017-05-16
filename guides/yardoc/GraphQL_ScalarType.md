---
layout: doc_stub
search: true
title: GraphQL::ScalarType
url: http://www.rubydoc.info/gems/graphql/GraphQL/ScalarType
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/ScalarType
---

Class: GraphQL::ScalarType < GraphQL::BaseType
# GraphQL::ScalarType 
Scalars are plain values. They are leaf nodes in a GraphQL query
tree. 
## Built-in Scalars 
`GraphQL` comes with standard built-in scalars: 
|Constant | `.define` helper| | | |
|`GraphQL::STRING_TYPE` | `types.String`| |`GraphQL::INT_TYPE` |
`types.Int`| |`GraphQL::FLOAT_TYPE` | `types.Float`|
|`GraphQL::ID_TYPE` | `types.ID`| |`GraphQL::BOOLEAN_TYPE` |
`types.Boolean`| 
(`types` is an instance of `GraphQL::Definition::TypeDefiner`;
`.String`, `.Float`, etc are methods which return built-in scalars.)
## Custom Scalars 
You can define custom scalars for your GraphQL server. It requires
some special functions: 
- `coerce_input` is used to prepare incoming values for GraphQL
execution. (Incoming values come from variables or literal values in
the query string.) - `coerce_result` is used to turn Ruby values
_back_ into serializable values for query responses. 
Examples:
# defining a type for Time
TimeType = GraphQL::ScalarType.define do
name "Time"
description "Time since epoch in seconds"
coerce_input ->(value, ctx) { Time.at(Float(value)) }
coerce_result ->(value, ctx) { value.to_f }
end
Instance methods:
coerce=, coerce_input=, coerce_non_null_input, coerce_result,
coerce_result=, ensure_two_arg, get_arity, initialize, kind,
validate_non_null_input

