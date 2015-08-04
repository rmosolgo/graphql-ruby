# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

 - [Introduction](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/introduction.md)
 - [API Documentation](http://www.rubydoc.info/github/rmosolgo/graphql-ruby)

## Overview

- __Install the gem__:

  ```ruby
  # Gemfile
  gem 'graphql'
  ```

  ```
  $ bundle install
  ```

- __Declare types & build a schema__:

  ```ruby
  # Declare a type...
  PostType = GraphQL::ObjectType.new do |t, types, field|
    t.name "Post"
    t.description "A blog post"
    t.fields({
      id:       field.build(type: !types.Int),
      title:    field.build(type: !types.String),
      body:     field.build(type: !types.String),
      comments: field.build(type: types[!CommentType])
    })
  end

  # ...and a query root
  QueryType = GraphQL::ObjectType.new do |t, types, field, arg|
    t.name "Query"
    t.description "The query root of this schema"
    t.fields({
      post: GraphQL::Field.new do |f|
        f.arguments(id: arg.build(type: !types.Int))
        f.resolve -> (object, args, context) {
          Post.find(args["id"])
        }
      end
    })
  end

  # Then create your schema
  Schema = GraphQL::Schema.new(query: QueryType, mutation: nil)
  ```

  See also:
    - the [test schema](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/support/dummy_app.rb)
    - [`graphql-ruby-demo`](https://github.com/rmosolgo/graphql-ruby-demo) for an example schema on Rails

- __Execute queries__:

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
  - [query_spec.rb](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/graph_ql/query_spec.rb) for an example of query execution.
  -  [`queries_controller.rb`](https://github.com/rmosolgo/graphql-ruby-demo/blob/master/app/controllers/queries_controller.rb) for a Rails example
  - Try it on [heroku](http://graphql-ruby-demo.herokuapp.com)

## To Do

- To match spec:
  - Directives:
    - `@skip` has precedence over `@include`
    - directives on fragments: http://facebook.github.io/graphql/#sec-Fragment-Directives
  - `__type { fields }` shouldn't include `__typename` https://github.com/graphql/graphql-js/issues/73#issuecomment-123119823
- Field merging
  - if you were to request a field, then request it in a fragment, it would get looked up twice
  - https://github.com/graphql/graphql-js/issues/19#issuecomment-118515077
- Code clean-up
  - Unify unwrapping types (It's on `TypeKind` but it's still not right)
  - Use StarWarsSchema for tests
- Cook up some path other than "n+1s everywhere"
  - See Sangria's `project` approach


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
