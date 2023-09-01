---
layout: guide
search: true
section: Authorization
title: Schema Subsets
desc: Define subsets of your schema for clients to see
index: 2
---

You can define **schema subsets** which are static subsets of your GraphQL schema's types, fields and arguments. Each query can include `context: { schema_subset: ... }` to run with a specific subset.

You can use this to hide parts of your schema from some clients while showing them to other clients. This feature is _like_ {% internal_link "Visibility", "/authorization/visibility" %}, except that each subset is cached and re-used between queries. This makes it faster but less flexible.

## Defining subsets

To define a subset, name it in the schema. For example, to support `{ schema_subset: :admin }`:

```ruby
class MySchema < GraphQL::Schema
  # ...
  subset :admin
end
```

Then, to connect types with certain subsets, add `subsets ...` to the type definition. For example, to make `Types::Invoice` visible to `:admin` only:

```ruby
class Types::Invoice < Types::BaseObject
  subsets :admin
end
```

Now, `Types::Invoice` will be hidden from any query that _doesn't_ have `context: { schema_subset: :admin, ... }`.

You can also put fields and arguments in subsets with `subsets: [:admin]` in your `field` or `argument` definitions. When configured that way, fields and arguments will be hidden unless `context[:schema_subset]` matches one of its configured subsets.

Interface implementations can be put in subsets by adding `implements ..., subsets: [:admin]`. That way, an object's implementation of an interface will be hidden when`context[:schema_subset]` isn't one of the subsets configured for the implementation. Also, any fields inherited from the interface (that is, not defined in the object type itself) will be hidden in that case.

Union memberships can be put in subsets by adding `possible_types ..., subsets: [:admin]`. With that configuration, an object type won't appear as a union member when `context[:schema_subset]` isn't one of the configured subsets.

## Using subsets

To specify a subset for executing a query, add `schema_subset: ...` to the query's `context: { ... }` hash. For example, in your GraphQL controller:

```ruby
context = {
  schema_subset: current_user.present? ? :logged_in : :logged_out
}
result = MyAppSchema.execute(params[:query], context: context, ...)
```

## `:default` subset

Every schema has a `:default` subset which includes the _whole_ schema. If you know that nothing in your schema will be hidden in the current query, you can use `context: { schema_subset: :default }` to skip all `visible?` checks at runtime.

## Tracking changes

To manage your sub-schemas in development, keep a schema dump in your repository and keep it up to date ([blog post](https://rmosolgo.github.io/ruby/graphql/2017/03/16/tracking-schema-changes-with-graphql-ruby.html)). You can add `context:` to your schema dumps:

```ruby
logged_out_schema_str = MyAppSchema.to_definition(context: { schema_subset: :logged_out })
assert_equal logged_out_schema_str, File.read("test/logged_out_schema.graphql"), "The schema dump is up-to-date"
```

## Context-based subsets

The easiest way to define a schema subset is to use a _name_, with `subsets` configurations in your schema definition. But you can also define a subset by using an example context:

```ruby
class MySchema < GraphQL::Schema
  # ...
  subset :staff, context: { staff: true }
  subset :superuser_staff, context: { staff: true, superuser: true }
end
```

In that case, the subset will be created using the example `context`.  Queries may use `context[:schema_subset] = ...` to pick one of the prepared subsets, for example:

```ruby
# Use the prepared subset:
MySchema.execute(query_str, context: { schema_subset: :superuser_staff })
```

In that case, the already-prepared subset will be used for this query. The `context` given to `subset :superuser_staff, ...` in the _schema definition_ was already passed to `visible?` methods on types and fields -- the runtime query context won't be used for that.
