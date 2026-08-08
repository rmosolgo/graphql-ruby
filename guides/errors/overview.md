# Errors in GraphQL

There are a _lot_ of different kinds of errors in GraphQL! In this guide, we'll discuss some of the main categories and learn when they apply.

## Validation Errors

Because GraphQL is strongly typed, it performs validation of all queries before executing them. If an incoming query is invalid, it isn't executed. Instead, a response is sent back with `"errors"`:

```ruby
{
  "errors" => [ ... ]
}
```

Each error has a message, line, column and path.

The validation rules are part of the GraphQL specification and built into GraphQL-Ruby, so there's not really a way to customize this behavior, except to pass `validate: false` when executing a query, which skips validation altogether.

You can configure your schema to stop validating after a certain number of errors by setting [Schema.validate_max_errors](rdoc-ref:GraphQL::Schema.validate_max_errors). Also, you can add a timeout to this step with [Schema.validate_timeout](rdoc-ref:GraphQL::Schema.validate_timeout).

## Analysis Errors

GraphQL-Ruby supports pre-execution analysis, which may return `"errors"` instead of running a query. You can find details in the [Analysis guide](/queries/ast_analysis).

## GraphQL Invariants

While GraphQL-Ruby is executing a query, some constraints must be satisfied. For example:

- Non-null fields may not return `nil`.
- Interface and union types must resolve objects to types that belong to that interface/union.

These constraints are part of the GraphQL specification, and when they are violated, it must be addressed somehow. Read more in [Type Errors](/errors/type_errors).

## Top-level `"errors"`

The GraphQL specification provides for a top-level `"errors"` key which may include information about errors during query execution. `"errors"` and `"data"` may _both_ be present in the case of a partial success.

In your own schema, you can add to the `"errors"` key by raising `GraphQL::ExecutionError` (or subclasses of it) in your code. Read more in the [Execution Errors guide](/errors/execution_errors).

## Handled Errors

A schema can be configured to handle certain errors during field execution with handlers that you give it, using `rescue_from`. Read more in the [Error Handling guide](/errors/error_handling).

## Unhandled Errors (Crashes)

When a `raise`d error is not `rescue`d, the GraphQL query crashes entirely and the surrounding code (like a Rails controller) must handle the exception.

For example, Rails will probably return a generic `500` page.

## Errors as Data

When you want end users (human beings) to read error messages, you can express errors _in the schema_, using normal GraphQL fields and types. In this approach, errors are strongly-typed data, queryable in the schema, like any other application data.

For more about this approach, see [Mutation Errors](/mutations/mutation_errors.html#errors-as-data)
