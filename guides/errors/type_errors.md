---
layout: guide
doc_stub: false
search: true
section: Errors
title: Type Errors
desc: Handling type errors
index: 3
---

The GraphQL specification _requires_ certain assumptions to hold true when executing a query. However, it's possible that some code would violate that assumption, resulting in a type error.

Here are some type errors that you can customize in GraphQL-Ruby:

- A field with `null: false` returned `nil`
- A field returned a value as a union or interface, but that value couldn't be resolved to a member of that union or interface.
- A built-in scalar received an out-of-bounds or wrongly-encoded value from a client or from the application

You can specify behavior in these cases by defining a {{ "Schema.type_error" | api_doc }} hook:

```ruby
class MySchema < GraphQL::Schema
  def self.type_error(err, query_ctx)
    # Handle a failed runtime type coercion
  end
end
```

It is called with an instance of {{ "GraphQL::UnresolvedTypeError" | api_doc }} or {{ "GraphQL::InvalidNullError" | api_doc }} and the query context (a {{ "GraphQL::Query::Context" |  api_doc }}).

If you don't specify a hook, you get the default behavior ({{ "GraphQL::Schema::DefaultTypeResolve" | api_doc }}):

- Unresolved Union / Interface types raise {{ "GraphQL::UnresolvedTypeError" | api_doc }} and halt the query
- Application-returned strings that aren't in UTF-8 encoding raise {{ "GraphQL::StringEncodingError" | api_doc }}s and halt the query
- Application-returned integers beyond the GraphQL specification's limit raise {{ "GraphQL::IntegerEncodingError" | api_doc }}s and halt the query
- Client-provided integers beyond the GraphQL specification's limit pass {{ "GraphQL::IntegerDecodingError" | api_docs }}s to this method, and they're replaced with `nil`
- An application-returned `nil` for a field configured with `null: false` passes a {{ "GraphQL::InvalidNullError" | api_doc }} to this method, but it's silently ignored
An object that fails type resolution is treated as `nil`.
