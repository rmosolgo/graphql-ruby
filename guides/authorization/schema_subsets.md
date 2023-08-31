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

## Using subsets

To specify a subset for executing a query, add `schema_subset: ...` to the query's `context: { ... }` hash. For example, in your GraphQL controller:

```ruby
context = {
  schema_subset: current_user.present? ? :logged_in : :logged_out
}
result = MyAppSchema.execute(params[:query], context: context, ...)
```

## Tracking changes

To manage your sub-schemas in development, keep a schema dump in your repository and keep it up to date ([blog post](https://rmosolgo.github.io/ruby/graphql/2017/03/16/tracking-schema-changes-with-graphql-ruby.html)). You can add `context:` to your schema dumps:

```ruby
logged_out_schema_str = MyAppSchema.to_definition(context: { schema_subset: :logged_out })
assert_equal logged_out_schema_str, File.read("test/logged_out_schema.graphql"), "The schema dump is up-to-date"
```
