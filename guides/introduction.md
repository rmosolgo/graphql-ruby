---
title: Introduction to `graphql-ruby`
---

A GraphQL system exposes your application to the world according to its _schema_. A schema includes:

- _Types_ which expose objects in your application
- _Fields_ which expose properties of those objects (and may connect types to other types)
- _Query root_, which is a special type used for executing read queries
- _Mutation root_, which is a special type used for executing mutations

Once you've defined your query root and mutation root, you can make a schema:

```ruby
ApplicationSchema = GraphQL::Schema.define do
  query QueryRoot
  mutation MutationRoot
end
```

At that time, `graphql-ruby` will validate all types and fields.

## Getting Started with Types

Create types to wrap objects & expose data through fields.  

Let's imagine we have a blog with only a `Post` model (no comments yet :) :

```ruby
class Post
  attr_accessor :id, :title, :body
  def self.find(id)
    # get a Post from the database
  end
end
```

Let's make type for `Post`:

```ruby
# `types` is a helper for declaring GraphQL types
PostType = GraphQL::ObjectType.define do
  name "Post"
  description "A blog entry"

  field :id, !types.ID, "The unique ID for this post"
  field :title, !types.String, "The title of this post"
  field :body, !types.String,  "The body of this post"
end
```

Now, posts will expose `id`, `title` and `body`. The `field` helper is good for fields that call methods with the same name. Using `!` defines fields as non-null.

However, the post type isn't accessible yet because it's not attached to a query root.

## Making a query root

A query root is "just" a type. Its fields don't call methods on some object, though -- instead, they retrieve objects which will be read.

```ruby
QueryRoot = GraphQL::ObjectType.define do
  name "Query"
  description "The query root for this schema"

  field :post do
    type PostType
    description "Find a Post by id"
    argument :id, !types.ID
    resolve ->(object, arguments, context) {
      Post.find(arguments["id"])
    }
  end
end
```

The query root has one field, `post`,  which finds a `Post` by ID. The `resolve` proc will be called with:

- `object`: The "parent" of this field (in the above case, it's the query root, not very useful)
- `arguments`: A hash with arguments passed to the field (keys will be strings)
- `context`: An arbitrary object defined when running the query (see [Executing queries](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/executing_queries.md))


## Creating a Schema

Lastly, create the schema:

```ruby
Schema = GraphQL::Schema.define do
  query QueryRoot
end
```

This schema could handle queries like:

```
{
  firstPost: post(id: 1) { title, body }
  nextPost:  post(id: 2) { title, body }
}
```

## Complex Types

Given a `Comment` model like this one, let's add it to our schema:

```ruby
class Comment
  attr_accessor :id, :body, :post_id
  def post
    # find this comment's post
  end
end
```

First, a `CommentType` to expose comments:

```ruby
CommentType = GraphQL::ObjectType.define do
  name "Comment"
  description "A reply to a post"

  field :id, !types.ID, "The unique ID of this comment"
  field :body, !types.String, "The content of this comment"
  field :post, !PostType, "The post this comment replies to"
end
```

Notice that the `post` field has `type: !PostType`. This means it returns a non-null `PostType` (which we defined above).

We should also add a `comments` field to `PostType`:

```ruby
PostType = GraphQL::ObjectType.new do |t, types, field|
  # ... existing code ...
  field :comments, !types[!CommentType], "Responses to this post"
end
```

`types[SomeType]` means that this field returns a _list_ of `SomeType`.

## Executing a Query

After defining your schema, you can evaluate queries with `GraphQL::Query`. For example:

```ruby
Schema = GraphQL::Schema.define do
  query QueryRoot # QueryRoot defined above
end

query_string = "query getPost { post(id: 1) { id, title, comments { body } } }"

result_hash = Schema.execute(query_string)
# {
#   "post" : {
#     "id" : 1,
#     "title" : "GraphQL is cool",
#     "comments" : [
#       { "body" : "Yep, sure is."},
#       { "body" : "Still gotta figure out that reducing executor though"}
#     ]
#   }
# }
```

## More Info

Read more in some other guides:

- [Defining Your Schema](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/defining_your_schema.md)
- [Executing Queries](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/executing_queries.md)
