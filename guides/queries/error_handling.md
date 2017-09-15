---
layout: guide
search: true
title: Error Handling
desc: Handle errors during execution
section: Queries
---

Sometimes errors happen! There are a few ways to express them in GraphQL:

- Expose errors _in_ the schema itself
- Add errors to the response's `"errors"` key

Additionally, you can provide opt-in error support by wrapping resolvers (described below).

## Exposing Errors

You can expose errors as part of your schema. In a sense, this makes errors part of "business as usual", instead of exceptional cases.

For example, you could add `errors` to `PostType`:

```ruby
PostType = GraphQL::ObjectType.define do
  name "Post"
  field :title, types.String
  # ...
  field :errors, types[types.String], "Reasons the object couldn't be created or updated" do
    resolve ->(obj, args, ctx) { obj.errors.full_messages }
  end
end
```

Then, when creating a post, return the `Post`, even if the save failed:

```ruby
resolve ->(obj, args, ctx) {
  post = Post.new(args["post"].to_h)
  # Maybe this fails, no big deal:
  post.save
  post
}
```

Then, when clients create a post, they should check the `errors` field to see if it was successful:

```graphql
mutation {
  createPost(post: {title: "GraphQL is Nice"}) {
    id
    title
    errors # in case the save failed
  }
}
```

If `errors` is present (and `id` is null), the client knows that the operation was unsuccessful, and they can discover why.

This technique could be extended by creating dedicated error types, too.

## The "errors" Key

A GraphQL response may have an `"errors"` key, for example:

```ruby
Schema.execute(query_string)
# {
#   "errors" => [
#     { "message" => "Something went wrong" },
#   ],
# }
```

You can add an error to the `"errors"` key by returning a {{ "GraphQL::ExecutionError" | api_doc }} from a `resolve` function. For example:

```ruby
resolve ->(obj, args, ctx) {
  post_params = args["post"].to_h
  if obj.posts.create(post_params)
    # on success, return the post:
    post
  else
    # on error, return an error:
    GraphQL::ExecutionError.new("Invalid input for Post: #{post.errors.full_messages.join(", ")}")
  end
}
```

If some part of your `resolve` function would raise an error, you can rescue it and return a {{ "GraphQL::ExecutionError" | api_doc }} instead:

```ruby
resolve ->(obj, args, ctx) {
  post_params = args["post"].to_h
  begin
    post = obj.posts.create!(post_params)
    # on success, return the post:
    post
  rescue ActiveRecord::RecordInvalid => err
    # on error, return an error:
    GraphQL::ExecutionError.new("Invalid input for Post: #{post.errors.full_messages.join(", ")}")
  end
}
```

## Error Handling with Wrappers

If you don't want to `begin ... rescue ... end` in every field, you can wrap `resolve` functions in error handling. For example, you could make an object that wraps another resolver:

```ruby
# Wrap field resolver `resolve_func` with a handler for `error_superclass`.
# `RescueFrom` instances are valid field resolvers too.
class RescueFrom
  def initialize(error_superclass, resolve_func)
    @error_superclass = error_superclass
    @resolve_func = resolve_func
  end

  def call(obj, args, ctx)
    @resolve_func.call(obj, args, ctx)
  rescue @error_superclass => err
    # Your error handling logic here:
    # - return an instance of `GraphQL::ExecutionError`
    # - or, return nil:
    nil
  end
end
```

Then, apply it to fields on an opt-in basis:

```ruby
field :create_post, PostType do
  # Wrap the resolve function with `RescueFrom.new(err_class, ...)`
  resolve RescueFrom.new(ActiveRecord::RecordInvalid, ->(obj, args, ctx) { ... })
end
```

This way, you get error handling with proper Ruby semantics and no overhead!
