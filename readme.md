# graphql <img src="https://cloud.githubusercontent.com/assets/2231765/9094460/cb43861e-3b66-11e5-9fbf-71066ff3ab13.png" height=40 alt="graphql-ruby"/>

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

A Ruby implementation of [GraphQL](http://graphql.org/).

 - Guides
     - [Introduction](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/introduction.md)
     - [Defining Your Schema](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/defining_your_schema.md)
     - [Executing Queries](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/executing_queries.md)
     - [Testing](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/testing.md)
     - [Server-Side Query Cache](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/server_side_queries.md)

 - [API Documentation](http://www.rubydoc.info/github/rmosolgo/graphql-ruby)

## Installation

Install from RubyGems by adding it to your `Gemfile`, then bundling.

```ruby
# Gemfile
gem 'graphql'
```

```
$ bundle install
```

## Overview

#### Declare types & build a schema

```ruby
# Declare a type...
PostType = GraphQL::ObjectType.define do
  name "Post"
  description "A blog post"

  field :id, !types.ID
  field :title, !types.String
  field :body, !types.String
  field :comments, types[!CommentType]
end

# ...and a query root
QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :post do
    type PostType
    argument :id, !types.ID
    resolve -> (obj, args, ctx) { Post.find(args["id"]) }
  end
end

# Then create your schema
Schema = GraphQL::Schema.new(
  query: QueryType,
  max_depth: 8,
)
```

#### Execute queries

Execute GraphQL queries on a given schema, from a query string.

```ruby
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

#### Use with Relay

If you're building a backend for [Relay](http://facebook.github.io/relay/), you'll need:

- A JSON dump of the schema, which you can get by sending [`GraphQL::Introspection::INTROSPECTION_QUERY`](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/introspection/introspection_query.rb)
- Relay-specific helpers for GraphQL like Connections, node fields, and global ids. Here's one example of those: [`graphql-relay`](https://github.com/rmosolgo/graphql-relay-ruby)

## Goals

- Implement the GraphQL spec & support a Relay front end
- Provide idiomatic, plain-Ruby API with similarities to reference implementation where possible
- Support Ruby on Rails and Relay

## Getting Involved

- __Say hi & ask questions__ in the [#ruby channel on Slack](https://graphql-slack.herokuapp.com/) or [on Twitter](https://twitter.com/rmosolgo)!
- __Report bugs__ by posting a description, full stack trace, and all relevant code in a  [GitHub issue](https://github.com/rmosolgo/graphql-ruby/issues).
- __Features & patches__ are welcome! Consider discussing it in an [issue](https://github.com/rmosolgo/graphql-ruby/issues) or in the [#ruby channel on Slack](https://graphql-slack.herokuapp.com/) to make sure we're on the same page.
- __Run the tests__ with `rake test` or start up guard with `bundle exec guard`.

## Related Projects

### Code

- `graphql-ruby` + Rails demo ([src](https://github.com/rmosolgo/graphql-ruby-demo) / [heroku](http://graphql-ruby-demo.herokuapp.com))
- [`graphql-batch`](https://github.com/shopify/graphql-batch), a batched query execution strategy
- [Example Relay support](https://github.com/rmosolgo/graphql-relay-ruby) in Ruby
- [`graphql-libgraphqlparser`](https://github.com/rmosolgo/graphql-libgraphqlparser), bindings to [libgraphqlparser](https://github.com/graphql/libgraphqlparser), a C-level parser.

### Blog Posts

-  Building a blog in GraphQL and Relay on Rails [Introduction](https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-getting-started-955a49d251de), [Part 1]( https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-creating-types-and-schema-b3f9b232ccfc), [Part 2](https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-first-relay-powered-react-component-cb3f9ee95eca)
- https://medium.com/@khor/relay-facebook-on-rails-8b4af2057152
- https://blog.jacobwgillespie.com/from-rest-to-graphql-b4e95e94c26b#.4cjtklrwt
- http://mgiroux.me/2015/getting-started-with-rails-graphql-relay/
- http://mgiroux.me/2015/uploading-files-using-relay-with-rails/

## To Do

- Type lookup should be by type name (to support reloaded constants in Rails code)
- Add a complexity validator (reject queries if they're too big)
- Add docs for shared behaviors & DRY code
- Revamp the fixture Schema to be more useful (better names, more extensible)
- Fix when a field's type is left out `field :name, "This is the name field"`
- Revisit error handling & `debug:` option
- Trying to send a `mutation` without a MutationType gives `no method #unwrap for nil`
- __Subscriptions__
  - This is a good chance to make an `Operation` abstraction of which `query`, `mutation` and `subscription` are members
  - For a subscription, `graphql` would send an outbound message to the system (allow the host application to manage its own subscriptions via Pusher, ActionCable, whatever)
