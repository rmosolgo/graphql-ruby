# Type Errors

The GraphQL specification _requires_ certain assumptions to hold true when executing a query. However, it's possible that some code would violate that assumption, resulting in a type error.

Here are two type errors that you can customize in GraphQL-Ruby:

- A field with `null: false` returned `nil`
- A field returned a value as a union or interface, but that value couldn't be resolved to a member of that union or interface.

You can specify behavior in these cases by defining a [Schema.type_error](rdoc-ref:GraphQL::Schema.type_error) hook:

```ruby
class MySchema < GraphQL::Schema
  def self.type_error(err, query_ctx)
    # Handle a failed runtime type coercion
  end
end
```

It is called with an instance of [GraphQL::UnresolvedTypeError](rdoc-ref:GraphQL::UnresolvedTypeError) or [GraphQL::InvalidNullError](rdoc-ref:GraphQL::InvalidNullError) and the query context (a [GraphQL::Query::Context](rdoc-ref:GraphQL::Query::Context)).

If you don't specify a hook, you get the default behavior:

- Unexpected `nil`s add an error the response's `"errors"` key
- Unresolved Union / Interface types raise [GraphQL::UnresolvedTypeError](rdoc-ref:GraphQL::UnresolvedTypeError)

An object that fails type resolution is treated as `nil`.
