---
layout: guide
doc_stub: false
search: true
section: Fields
title: Arguments
desc: Fields may take arguments as inputs
index: 2
---

Fields can take __arguments__ as input. These can be used to determine the return value (eg, filtering search results) or to modify the application state (eg, updating the database in `MutationType`).

Arguments are defined with the `argument` helper:

```ruby
field :search_posts, types[PostType] do
  argument :category, types.String
  resolve ->(obj, args, ctx) {
    args[:category]
    # => maybe a string, eg "Programming"
    if args[:category]
      Post.where(category: category).limit(10)
    else
      Post.all.limit(10)
    end
  }
end
```

Use `!` to mark an argument as _required_:

```ruby
# This argument is a required string:
argument :category, !types.String
```

Use `default_value: value` to provide a default value for the argument if not supplied in the query.

```ruby
argument :category, types.String, default_value: "Programming"
```

Use `as: :alternateName` to use a different key from within your resolvers while
exposing another key to clients.

```ruby
field :post, PostType do
  argument :postId, types.Id, as: :id
  resolve ->(obj, args, ctx) {
    Post.find(args['id'])
  }
end
```

Provide a `prepare` function to modify or validate the value of an argument before the field's `resolve` function is executed:

```ruby
field :posts, types[PostType] do
  argument :startDate, types.String, prepare: ->(startDate, ctx) {
    # return the prepared argument or GraphQL::ExecutionError.new("msg")
    # to halt the execution of the field and add "msg" to the `errors` key.
  }
  resolve ->(obj, args, ctx) {
    # use prepared args['startDate']
  }
end
```

Only certain types are valid for arguments:

- {{ "GraphQL::ScalarType" | api_doc }}, including built-in scalars (string, int, float, boolean, ID)
- {{ "GraphQL::EnumType" | api_doc }}
- {{ "GraphQL::InputObjectType" | api_doc }}, which allows key-value pairs as input
- {{ "GraphQL::ListType" | api_doc }}s of a valid input type
- {{ "GraphQL::NonNullType" | api_doc }}s of a valid input type


The `args` parameter of a `resolve` function will always be a {{ "GraphQL::Query::Arguments" | api_doc }}. You can access specific arguments with `["arg_name"]` or `[:arg_name]`. You recursively turn it into a Ruby Hash with `to_h`. Inside `args`, scalars will be parsed into Ruby values and enums will be converted to their `value:` (if one was provided).

```ruby
resolve ->(obj, args, ctx) {
  args["category"] == args[:category]
  # => true
  args.to_h
  # => { "category" => "Programming" }
  # ...
}
```
