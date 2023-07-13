---
layout: guide
search: true
section: Authorization
title: Shapes
desc: Define subsets of your schema for clients to see
index: 2
---

You can define **schema shapes** which are static subsets of your GraphQL schema's types, fields and arguments. Each query can include `context: { schema_shape: ... }` to run with a specific shape.

You can use this to hide parts of your schema from some clients while showing them to other clients. This feature is _like_ {% internal_link "Visibility", "/authorization/visibility" %}, except that each shape is cached and re-used between queries. This makes it faster but less flexible.

## Defining shapes

To define a shape, name it in the schema. For example, to support `{ schema_shape: :admin }`:

```ruby
class MySchema < GraphQL::Schema
  # ...
  shape :admin
end
```

Then, to connect types with certain shapes, add `shapes ...` to the type definition. For example, to make `Types::Invoice` visible to `:admin` only:

```ruby
class Types::Invoice < Types::BaseObject
  shapes :admin
end
```

Now, `Types::Invoice` will be hidden from any query that _doesn't_ have `context: { schema_shape: :admin, ... }`.

## Using shapes

To specify a shape for executing a query, add `schema_shape: ...` to the query's `context: { ... }` hash. For example, in your GraphQL controller:

```ruby
context = {
  schema_shape: current_user.present? ? :logged_in : :logged_out
}
result = MyAppSchema.execute(params[:query], context: context, ...)
```

## Tracking changes

To manage your sub-schemas in development, keep a schema dump in your repository and keep it up to date ([blog post](https://rmosolgo.github.io/ruby/graphql/2017/03/16/tracking-schema-changes-with-graphql-ruby.html)). You can add `context:` to your schema dumps:

```ruby
logged_out_schema_str = MyAppSchema.to_definition(context: { schema_shape: :logged_out })
assert_equal logged_out_schema_str, File.read("test/logged_out_schema.graphql"), "The schema dump is up-to-date"
```
