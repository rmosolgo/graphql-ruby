# graphql <img src="https://cloud.githubusercontent.com/assets/2231765/9094460/cb43861e-3b66-11e5-9fbf-71066ff3ab13.png" height=40 alt="graphql-ruby"/>

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

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
query = GraphQL::Query.new(Schema, query_string)
result_hash = query.result
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

## To Do

- To match spec:
  - Directives:
    - `@skip` has precedence over `@include`
    - directives on fragments: http://facebook.github.io/graphql/#sec-Fragment-Directives
  - Union
    - only require one type https://github.com/facebook/graphql/commit/972fd5aae01195b018d305c82e43f714f9a41679
- Field merging
  - if you were to request a field, then request it in a fragment, it would get looked up twice
  - https://github.com/graphql/graphql-js/issues/19#issuecomment-118515077
- Code clean-up
  - Accept native Ruby types in definitions, then convert them to GraphQL types
  - Make Schema validations run before TypeReducer
  - Remove deprecated `params:` keyword
  - Make sure to raise if you try to configure an attribute which doesnt suit the type
- Cook up some path other than "n+1s everywhere"
  - See Sangria's `project` approach ([in progress](https://github.com/rmosolgo/graphql-ruby/pull/15))

## Goals

- Implement the GraphQL spec & support a Relay front end
- Provide idiomatic, plain-Ruby API with similarities to reference implementation where possible
- Support `graphql-rails`

## Getting Involved

- __Say hi & ask questions__ in the [#ruby channel on Slack](https://graphql-slack.herokuapp.com/) or [on Twitter](https://twitter.com/rmosolgo)!
- __Report bugs__ by posting a description, full stack trace, and all relevant code in a  [GitHub issue](https://github.com/rmosolgo/graphql-ruby/issues).
- __Features & patches__ are welcome! Consider discussing it in an [issue](https://github.com/rmosolgo/graphql-ruby/issues) or in the [#ruby channel on Slack](https://graphql-slack.herokuapp.com/) to make sure we're on the same page.
- __Run the tests__ with `rake test` or start up guard with `bundle exec guard`.

## Other Resources

- [GraphQL Spec](http://facebook.github.io/graphql/)
- Other implementations: [graphql-links](https://github.com/emmenko/graphql-links)
- `graphql-ruby` + Rails demo ([src](https://github.com/rmosolgo/graphql-ruby-demo) / [heroku](http://graphql-ruby-demo.herokuapp.com))
- [GraphQL Slack](https://graphql-slack.herokuapp.com/)

## P.S.

- Thanks to @sgwilym for the great logo!
- Definition API heavily inspired by @seanchas's [implementation of GraphQL](https://github.com/seanchas/graphql)
