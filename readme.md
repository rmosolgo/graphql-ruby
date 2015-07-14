# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

## Overview

- Install the gem:

  ```ruby
  # Gemfile
  gem 'graphql'
  ```

- Build a schema:
  - See the [test schema](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/support/dummy_app.rb) for an example GraphQL schema in Ruby.
  - See [`graphql-ruby-demo`](https://github.com/rmosolgo/graphql-ruby-demo) for an example schema on Rails

- Execute queries
  - See [query_spec.rb](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/graph_ql/query_spec.rb) for an example of query execution.
  - See [`queries_controller.rb`](https://github.com/rmosolgo/graphql-ruby-demo/blob/master/app/controllers/queries_controller.rb) for a Rails example


## To Do:

- Validations:
  - implement lots of validators
  - implement `TypeStack` to provide type info to validators
- directives:
  - `@skip` has precedence over `@include`
  - directives on fragments: http://facebook.github.io/graphql/#sec-Fragment-Directives
- Support any "real" value for enum, not just stringified name (see `Character::EPISODES` in demo)
- field merging (https://github.com/graphql/graphql-js/issues/19#issuecomment-118515077)
- Code clean-up
  - every helper yields `|self, type, field, arg|`
  - Unify unwrapping types (see `FieldsAreDefinedOnType#get_type`)

## Goals:

- Implement the GraphQL spec & support a Relay front end
- Provide idiomatic, plain-Ruby API with similarities to reference implementation where possible
- Support `graphql-rails`
