---
layout: guide
search: true
section: Types
title: Scalar Types
desc: Scalars define values which are returned from fields
index: 2
---

Scalars are plain values. They are leaf nodes in a GraphQL query result.

## Built-in Scalars

`GraphQL` comes with standard built-in scalars:

|Constant | `.define` helper|
|-------|--------|
|`GraphQL::STRING_TYPE` | `types.String`|
|`GraphQL::INT_TYPE` | `types.Int`|
|`GraphQL::FLOAT_TYPE` | `types.Float`|
|`GraphQL::ID_TYPE` | `types.ID`|
|`GraphQL::BOOLEAN_TYPE` | `types.Boolean`|

(`types` is an instance of `GraphQL::Definition::TypeDefiner`; `.String`, `.Float`, etc are methods which return built-in scalars.)

## Custom Scalars

You can define custom scalars for your GraphQL server. It requires some special functions:

- `coerce_input` is used to prepare incoming values for GraphQL execution. (Incoming values come from variables or literal values in the query string.)
- `coerce_result` is used to turn Ruby values _back_ into serializable values for query responses.

For example, to define a type for Time:

```ruby
  TimeType = GraphQL::ScalarType.define do
    name "Time"
    description "Time since epoch in seconds"

    coerce_input ->(value, ctx) { Time.at(Float(value)) }
    coerce_result ->(value, ctx) { value.to_f }
  end
```
