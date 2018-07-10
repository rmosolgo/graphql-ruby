---
layout: guide
doc_stub: false
search: true
title: Getting Started
section: Other
desc: Start here!
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

On Rails, you can get started with a few [GraphQL generators](https://rmosolgo.github.io/graphql-ruby/schema/generators#graphqlinstall):

```sh
# Add graphql-ruby boilerplate and mount graphiql in development
rails g graphql:install
# Make your first object type
rails g graphql:object Post title:String rating:Int comments:[Comment]
```

Or, you can build a GraphQL server by hand:

- Define some types
- Connect them to a schema
- Execute queries with your schema

### Declare types

Types describe objects in your application and form the basis for [GraphQL's type system](http://graphql.org/learn/schema/#type-system).

```ruby
# app/graphql/post_type.graphql
class PostType < GraphQL::Schema::Object
  description "A blog post"
  field :id, ID, null: false
  field :title, String, null: false
  # Fields can return lists of other objects:
  field :comments, [CommentType], null: true,
    # And fields can have their own descriptions:
    description: "This post's comments, or null if this post has comments disabled."
end

# app/graphql/comment_type.graphql
class CommentType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :post, PostType, null: false
end
```

### Build a Schema

Before building a schema, you have to define an [entry point to your system, the "query root"](http://graphql.org/learn/schema/#the-query-and-mutation-types):

```ruby
class QueryType < GraphQL::Schema::Object
  description "The query root of this schema"

  # First describe the field signature:
  field :post, PostType, null: true do
    description "Find a post by ID"
    argument :id, ID, required: true
  end

  # Then provide an implementation:
  def post(id:)
    Post.find(id)
  end
end
```

Then, build a schema with `QueryType` as the query entry point:

```ruby
class Schema < GraphQL::Schema
  query QueryType
end
```

This schema is ready to serve GraphQL queries! {% internal_link "Browse the guides","/guides" %} to learn about other GraphQL Ruby features.

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

See {% internal_link "Executing Queries","/queries/executing_queries" %} for more information about running queries on your schema.

## Use with Relay

If you're building a backend for [Relay](http://facebook.github.io/relay/), you'll need:

- A JSON dump of the schema, which you can get by sending [`GraphQL::Introspection::INTROSPECTION_QUERY`](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/introspection/introspection_query.rb)
- Relay-specific helpers for GraphQL, see the `GraphQL::Relay` guides.

## Use with Apollo Client

[Apollo Client](http://dev.apollodata.com/) is a full featured, simple to use GraphQL client with convenient integrations for popular view layers. You don't need to do anything special to connect Apollo Client to a `graphql-ruby` server.

## Use with GraphQL.js Client

[GraphQL.js Client](https://github.com/f/graphql.js) is a tiny client that is platform- and framework-agnostic. It works well with `graphql-ruby` servers, since GraphQL requests are simple query strings transport over HTTP.
