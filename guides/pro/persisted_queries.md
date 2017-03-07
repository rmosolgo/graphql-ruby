---
title: GraphQL::Pro — Persisted Queries
---


`GraphQL::Pro::Repository` brings __persisted queries__ to Ruby! In this approach, GraphQL queries are written to `.graphql` files and stored on the server. Then, clients may execute those predefined queries by name (using [`operationName`](http://graphql.org/learn/queries/#operation-name)).

This provides several benefits:

- Improved security: you can serve GraphQL without accepting arbitrary queries.
- Improved stability: `.graphql` files are checked into source control and reviewed as first-class elements of the project.
- Improved maintainability: If your _entire_ GraphQL usage is described by a set of `.graphql` files, you can identify unused code and remove it.

To make a repository, define one with a `schema` and a `path`:

```ruby
# app/graphql/web_repository.rb
WebRepository = GraphQL::Pro::Repository.define do
  schema MySchema
  path Rails.root.join("app/graphql/documents/")
end
```

Then, you can execute queries by name with `Repository#execute`:

```ruby
result = WebRepository.execute(
  operation_name: params[:operationName]
  variables: ensure_hash(params[:variables])
  context: {
    user: current_user
  }
)
render json: result
```

Notice that no query string is provided, only an `operation_name:`. If the named operation is not in the repository, the client will receive an error.

Read on for more details about `GraphQL::Pro::Repository`:

- [Client usage](#client-usage)
- [Accepting other input](#arbitrary-input) (for example, GraphiQL)
- [Loading queries from other sources](#sources)
- [Watching files](#watching-files)
- [Analysis](#analysis)

## Client Usage

To execute an operation by name, send the operation name and query variables. For example, with jQuery:

```js
var payload = {
  operationName: "GetCards",
  variables: {
    listId: listId,
  },
}

$.post("/graphql", payload, responseHander)
```

Then, the server will use `params[:operationName]` to find an operation and execute it with `params[:variables]`.

## Arbitrary Input

Sometimes, you want to use static queries _or_ incoming query strings, for example:

- You want to use GraphiQL while writing your static queries
- You want to support existing clients while transitioning to static queries

For these cases, you can set the the `arbitrary_input` setting:

```ruby
MyRepository = GraphQL::Pro::Repository.define do
  # ...
  # Execute a provided query string if there is one:
  arbitrary_input :execute
end
```

This setting has three values:

- `:crash`: If non-`nil` arbitrary input is provided, raise `ArgumentError`
- `:ignore` (default): Silently ignore provided query strings, use `operation_name` only
- `:execute`: If a query string is provided, execute that instead of using operations in the repository. If `operation_name` is present, it is looked up in the provided query string.

You can also specify `arbitrary_input` on a query-by-query basis:

```ruby
# Allow staff users to execute any query:
arbitrary_input = current_user.staff? ? :execute : :ignore
MyRepository.execute(query_str, operation_name: operation_name, arbitrary_input: arbitrary_input)
```

Or,

```ruby
# Support legacy clients:
arbitrary_input = legacy_client?(request.user_agent) ? :execute : :ignore
MyRepository.execute(query_str, operation_name: operation_name, arbitrary_input: arbitrary_input)
```

Of course, another option is to choose an execution platform at runtime:

```ruby
if legacy_client?(request.user_agent)
  MySchema.execute(...)
else
  MyRepository.execute(...)
end
```

## Sources

The easiest way to build a repository is from a set of files specified by `path`:

```ruby
AndroidRepository = GraphQL::Pro::Repository.define do
  schema MySchema
  path Rails.root.join("app/graphql/documents/android")
end
```

But you can also load GraphQL from a plain string:

```ruby
IOsRepository = GraphQL::Pro::Repository.define do
  schema MySchema
  # Load GraphQL from some other place:
  string RemoteStorage.read_all
end
```

But take care: initializing a repository is costly. During initialization, the source document is parsed, validated and partitioned by operation. For this reason, building repositories at runtime is not recommended.

## Watching Files

On Rails, repository `path`s are automatically watched using Rails' built-in reloading features. When a file in the path is edited, added, or removed, the repository reloads its documents.

```ruby
WebRepository = GraphQL::Pro::Repository.define do
  # `.graphql` files in app/graphql/documents will be watched for changes:
  path Rails.root.join("app/graphql/documents")
```

To manually reload a repository from its path, call `Repository#reload`, for example:

```ruby
WebRepository = GraphQL::Pro::Repository.define { ... }
# Reload the repository from .graphql files in its path:
WebRepository.reload
```

## Analysis

Static queries are great for tooling and analysis.

To find fields which are present in a schema but _not_ used in a repository, call `Repository#unused_fields`. It returns a hash of `type => [field, field, ... ]` pairs containing unused field definitions. For example:

```ruby
MyAppRepository.unused_fields
# {
#   #<GraphQL::ObjectType name="Card"> => [
#     #<GraphQL::Field name="rarity">,
#     #<GraphQL::Field name="cost">,
#   ]
# }
```

Before removing a field, consider whether any outstanding clients may depend on this field another way, either by sending arbitrary inputs or by consuming a different repository.

Stay tuned! A future `graphql-ruby` release will include query diffing which can be used to detect breaking changes in repositories.
