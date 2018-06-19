---
layout: guide
doc_stub: false
search: true
section: Fields
title: Introduction
desc: Implement fields and resolvers with the Ruby DSL
index: 0
---

{{ "GraphQL::ObjectType" | api_doc }}s and {{ "GraphQL::InterfaceType" | api_doc }}s may expose their values with _fields_. A field definition looks like this:

```ruby
PostType = GraphQL::ObjectType.define do
  # ...
  #     name  , type        , description (optional)
  field :title, types.String, "The title of the Post"
end
```

By default, fields are resolved by sending the name to the underlying object (eg `post.title` in the example above). 

You can use the `hash_key` option instead to force a hash lookup instead of the default behaviour:

```ruby
field :title, types.String, hash_key: :title
# resolved with `post[:title]` instead of `post.title`
```

You can define a different resolution by providing a `resolve` function:

```ruby
PostType = GraphQL::ObjectType.define do
  # ...
  #     name   , type        , description (optional)
  field :teaser, types.String, "The teaser of the Post" do
    # how to get the value?
    resolve ->(obj, args, ctx) {
      # first 40 chars of the body
      obj.body[0, 40]
    }
  end
end
```

The resolve function receives inputs:

- `object`: The underlying object for this type (above, a `Post` instance)
- `arguments`: The arguments for this field (see below, a {{ "GraphQL::Query::Arguments" | api_doc }} instance)
- `context`: The context for this query (see {% internal_link "Executing Queries","/queries/executing_queries" %}, a {{ "GraphQL::Query::Context" | api_doc }} instance)

In fact, the `field do ... end` block is passed to {{ "GraphQL::Field" | api_doc }}'s `.define` method, so you can define many things there:

```ruby
field do
  name "teaser"
  type types.String
  description "..."
  resolve ->(obj, args, ctx) { ... }
  deprecation_reason "Too long, use .title instead"
  complexity 2
end
```
