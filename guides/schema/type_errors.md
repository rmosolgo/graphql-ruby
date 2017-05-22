---
layout: guide
search: true
section: Schema
title: Handing Typecasting Errors
desc: Specify how GraphQL should handle errors when runtime objects don't match the expected types
---

In some cases, runtime data can cause GraphQL execution to reach an invalid state:

- A `resolve` function returned `nil` for a non-null type
- A `resolve` function's value couldn't be resolved to a valid Union or Interface member ({{ "Schema#resolve_type" | api_doc }} returned an unexpected value)

You can specify behavior in these cases by defining a {{ "Schema#type_error" | api_doc }} hook:

```ruby
MySchema = GraphQL::Schema.define do
  type_error ->(type_error, query_ctx) {
    # Handle a failed runtime type coercion
  }
end
```

It is called with an instance of {{ "GraphQL::UnresolvedTypeError" | api_doc }} or {{ "GraphQL::InvalidNullError" | api_doc }} and the query context (a {{ "GraphQL::Query::Context" |  api_doc }}).

If you don't specify a hook, you get the default behavior:

- Unexpected `nil`s add an error the response's `"errors"` key
- Unresolved Union / Interface types raise {{ "GraphQL::UnresolvedTypeError" | api_doc }}

An object that fails type resolution is treated as `nil`.
