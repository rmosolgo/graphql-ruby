# Introduction to `graphql-ruby`

A GraphQL system exposes your application to the world according to its _schema_. A schema includes:

- _Types_ which expose objects in your application
- _Fields_ which expose properties of those objects (and may connect types to other types)
- _Query root_, which is a special type used for executing read queries
- _Mutation root_, which is a special type used for executing mutations

Once you've defined your query root and mutation root, you can make a schema:

```ruby
ApplicationSchema = GraphQL::Schema.new(query: QueryRoot, mutation: MutationRoot)
```

At that time, `graphql-ruby` will inspect all types & fields, ensuring that they implement required behaviors.

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
# `t` is the newly-created type
# `types` is a helper for declaring GraphQL types
PostType = GraphQL::ObjectType.new do |t, types, field|
  t.name "Post"
  t.description "A blog entry"
  t.fields({
    id:     field.build(type: !types.Int,     desc: "The unique ID for this post"),
    title:  field.build(type: !types.String,  desc: "The title of this post"),
    body:   field.build(type: !types.String,  desc: "The body of this post"),
  })
end
```

Now, posts will expose `id`, `title` and `body`. The `field` helper is good for fields that call methods with the same name. Using `!` defines fields as non-null.

However, the post type isn't accessible yet because it's not attached to a query root.

## Making a query root

A query root is "just" a type. Its fields don't call methods on some object, though -- instead, they retrieve objects which will be read.

#### A query field

First, let's define a field for finding `Post` objects:

```ruby
PostFindField = GraphQL::Field.new do |f, types, field, arg|
  f.description "Find a Post by id"
  # Return type of this field:
  f.type PostType
  # Arguments which this field expects:
  f.arguments({id: arg.build({type: !types.Int})})
  # How to fulfill this field:
  f.resolve -> (object, arguments, context) { Post.find(arguments["id"]) }
end
```

The `resolve` proc will be called with:

- `object`: The "parent" of this field (in the above case, it's the query root, not very useful)
- `arguments`: A hash with arguments passed to the field (keys will be strings)
- `context`: An arbitrary object defined when running the query (see [Executing queries](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/executing_queries.md))

#### The query root type

Next, create a type which has that field. We'll mount `PostFindField` with the name `post`.

```ruby
QueryRoot = GraphQL::ObjectType.new do |t|
  t.name "Query"
  t.description "The query root for this schema"
  t.fields({
    post: PostFindField,
  })
end
```

Lastly, create the schema:

```ruby
Schema = GraphQL::Schema.new(query: QueryRoot, mutation: nil)
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
CommentType = GraphQL::ObjectType.new do |t, types, field|
  t.name "Comment"
  t.description "A reply to a post"
  t.fields({
    id:   field.build(type: !types.Int, desc: "The unique ID of this comment"),
    body: field.build(type: !types.String, desc: "The content of this comment"),
    post: field.build(type: !PostType, desc: "The post this comment replies to"),
  })
end
```

Notice that the `post` field has `type: !PostType`. This means it returns a non-null `PostType` (which we defined above).

We should also add a `comments` field to `PostType`:

```ruby
PostType = GraphQL::ObjectType.new do |t, types, field|
  # ... existing code ...
  t.fields({
    # ... existing field defs ...
    comments: field.build(type: !types[!CommentType], description: "Responses to this post")  
  })
end
```

`types[{SomeType}]` means that this field returns a _list_ of `SomeType`.

There's a problem: `PostType` and `CommentType` have a circular dependency. You can't define `PostType` until `CommentType` is defined. You can't define `CommentType` until `PostType` is defined. Bummer.

To deal with this, wrap one of the types in a lambda with `-> { ... }`. For example, update the comments field:

```ruby
PostType = GraphQL::ObjectType.new do |t, types, field|
  # ... existing code ...
  t.fields({
    # ... existing field defs ...
    comments: field.build(type: -> { !types[!CommentType] } , description: "Responses to this post")  
  })
end
```

Notice `type: -> { ... }`. The lambda will be evaluated later, after CommentType has been defined.

## Executing a Query

After defining your schema, you can evaluate queries with `GraphQL::Query`. For example:

```ruby
Schema = GraphQL::Schema.new(query: QueryRoot, mutation: nil) # QueryRoot defined above
query_string = "query getPost { post(id: 1) { id, title, comments { body } } }"

query = GraphQL::Query.new(Schema, query_string)
response_hash = query.response
p JSON.dump(response_hash)
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

- [Type & Field Helpers](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/type_and_field_helpers.md)
- [Executing Queries](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/executing_queries.md)
- [Extending `graphql-ruby`](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/extending_graphql_ruby.md)
