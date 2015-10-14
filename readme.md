# graphql <img src="https://cloud.githubusercontent.com/assets/2231765/9094460/cb43861e-3b66-11e5-9fbf-71066ff3ab13.png" height=40 alt="graphql-ruby"/>

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

A Ruby implementation of [GraphQL](http://graphql.org/).

 - [Introduction](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/introduction.md)
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
Schema = GraphQL::Schema.new(query: QueryType)
```

See also:
  - the [test schema](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/support/dairy_app.rb)
  - [`graphql-ruby-demo`](https://github.com/rmosolgo/graphql-ruby-demo) for an example schema on Rails

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

See also:
  - [query_spec.rb](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/graphql/query_spec.rb) for an example of query execution.
  -  [`queries_controller.rb`](https://github.com/rmosolgo/graphql-ruby-demo/blob/master/app/controllers/queries_controller.rb) for a Rails example
  - Try it on [heroku](http://graphql-ruby-demo.herokuapp.com)

#### Use with Relay

If you're building a backend for [Relay](http://facebook.github.io/relay/), you'll need:

- A JSON dump of the schema, which you can get by sending [`GraphQL::Introspection::INTROSPECTION_QUERY`](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/introspection/introspection_query.rb)
- Relay-specific helpers for GraphQL like Connections, node fields, and global ids. Here's one example of those: [`graphql-relay`](https://github.com/rmosolgo/graphql-relay-ruby)


## To Do

- Code clean-up
  - Raise if you try to configure an attribute which doesn't suit the type
    - ie, if you try to define `resolve` on an ObjectType, it should somehow raise
  - Clean up file structure in `lib/schema` (don't need serial_execution namespace anymore)
  - support symbolized default values for input objects
  - Test `Inputs` coercion directly
  - Overriding `!` on types breaks ActiveSupport `.blank?`

    ```ruby
    my_type = GraphQL::ObjectType.define { name("MyType") }
    # => MyType
    my_type.present?
    # => MyType!!
    my_type.blank?
    # => MyType!
    ```
- Validate type of variables (see early return in LiteralValidator)
- Assert non-null variables are provided to the query at execution-time
- Big ideas:
  - Use [graphql-parser](https://github.com/shopify/graphql-parser) (Ruby bindings for [libgraphqlparser](https://github.com/graphql/libgraphqlparser)) instead of Parslet
  - Revamp the fixture Schema to be more useful (better names, more extensible)

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

- `graphql-ruby` + Rails demo ([src](https://github.com/rmosolgo/graphql-ruby-demo) / [heroku](http://graphql-ruby-demo.herokuapp.com))
- [`graphql-batch`](https://github.com/shopify/graphql-batch), a batched query execution strategy
- [`graphql-parallel`](https://github.com/rmosolgo/graphql-parallel), an asynchronous query execution strategy
- [Example Relay support](https://github.com/rmosolgo/graphql-relay-ruby) in Ruby

## P.S.

- Thanks to @sgwilym for the great logo!
- Definition API heavily inspired by @seanchas's [implementation of GraphQL](https://github.com/seanchas/graphql)
