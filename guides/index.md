---
title: Welcome
---

## Installation

You can install `graphql` from RubyGems by adding to your application's `Gemfile`:

```ruby
# Gemfile
gem "graphql"
```

Then, running `bundle install`:

```sh
$ bundle install
```

## Getting Started

Building a GraphQL server goes like this:

- Define some types
- Connect them to a schema
- Execute queries with your schema

### Declare types

Types describe objects in your application and form the basis for [GraphQL's type system](http://graphql.org/learn/schema/#type-system).

```ruby
PostType = GraphQL::ObjectType.define do
  name "Post"
  description "A blog post"
  # `!` marks a field as "required" or "non-null"
  field :id, !types.ID
  field :title, !types.String
  field :body, !types.String
  field :comments, types[!CommentType]
end

CommentType = GraphQL::ObjectType.define do
  name "Comment"
  field :id, !types.ID
  field :body, !types.String
  field :created_at, !types.String
end
```

### Build a Schema

Before building a schema, you have to define an [entry point to your system, the "query root"](http://graphql.org/learn/schema/#the-query-and-mutation-types):

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :post do
    type PostType
    argument :id, !types.ID
    description "Find a Post by ID"
    resolve -> (obj, args, ctx) { Post.find(args["id"]) }
  end
end
```

Then, build a schema with `QueryType` as the query entry point:

```ruby
Schema = GraphQL::Schema.define do
  query QueryType
end
```

This schema is ready to serve GraphQL queries! See ["Configuration Options"]({{ site.baseurl }}/schema/configuration_options) for all the schema options.

### Execute queries

You can execute queries from a query string:

```ruby
query_string = "
{
  post(id: 1) {
    id
    title
  }
}"
result_hash = Schema.execute(query_string)
# {
#   "data" => {
#     "post" => {
#        "id" => 1,
#        "title" => "GraphQL is nice"
#     }
#   }
# }
```

See ["Executing Queries"]({{ site.baseurl }}/queries/executing_queries) for more information about running queries on your schema.

## Use with Relay

If you're building a backend for [Relay](http://facebook.github.io/relay/), you'll need:

- A JSON dump of the schema, which you can get by sending [`GraphQL::Introspection::INTROSPECTION_QUERY`](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/introspection/introspection_query.rb)
- Relay-specific helpers for GraphQL, see the `GraphQL::Relay` guides.
