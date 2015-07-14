# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

__Current status__: rewriting according to spec, see also the previous [prototype implementation](https://github.com/rmosolgo/graphql-ruby/tree/74ad3c30a6d8db010ec3856f5871f8a02fcfba42)!

## Overview

- See the __[test schema](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/support/dummy_app.rb)__ for an example GraphQL schema in Ruby.
- See __[query_spec.rb](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/graph_ql/query_spec.rb)__ for an example of query execution.

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
