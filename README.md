# graphql-relay

[![Gem Version](https://badge.fury.io/rb/graphql-relay.svg)](http://badge.fury.io/rb/graphql-relay)
[![Build Status](https://travis-ci.org/rmosolgo/graphql-relay-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-relay-ruby)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby/coverage)

Helpers for using [`graphql`](https://github.com/rmosolgo/graphql-ruby) with Relay.

## Installation

```ruby
gem "graphql-relay"
```

```
bundle install
```

## Usage

### Global Ids

Global Ids provide refetching & global identification for Relay.

You should implement an object that responds to `#object_from_id(global_id)` & `#type_from_object(object)`, then pass it to `GraphQL::Relay::Node.create(implementation)`. [Example](https://github.com/rmosolgo/graphql-relay-ruby/blob/120b750cf86f1eb5c9997b588f022b2ef3a0012c/spec/support/star_wars_schema.rb#L4-L15)

Then, you can add global id fields to your types with `global_id_field` definition helper.
 [Example](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L29)

### Connections

Connections will provide arguments, pagination and `pageInfo` for `Array`s or `ActiveRecord::Relation`s. You can use the `connection` definition helper.

Then, implement the field. It's different than a normal field:
  - use the `connection` helper to define it, instead of `field`
  - Call `#connection_type` on an `ObjectType` for the field's return type (eg, `ShipType.connection_type`)
  - implement `resolve` to return an Array or an ActiveRecord::Relation, depending on the connection type.

[Example 1](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L39-L51), [Example 2](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L52-L58)

### Mutations

Mutations allow Relay to mutate your system. When you define a mutation, you'll be defining:
  - A field for your schema's `mutation` root
  - A derived `InputObjectType` for input values
  - A derived `ObjectType` for return values

You _don't_ define anything having to do with `clientMutationId`. That's automatically created.

To define a mutation, use `GraphQL::Relay::Mutation.define`. Inside the block, you should configure:
  - `name`, which will name the mutation field & derived types
  - `input_field`s, which will be applied to the derived `InputObjectType`
  - `return_field`s, which will be applied to the derived `ObjectType`
  - `resolve(-> (inputs, ctx))`, the mutation which will actually happen

The resolve proc:
  - Takes `inputs`, which is a hash whose keys are the ones defined by `input_field`
  - Takes `ctx`, which is the query context you passed with the `context:` keyword
  - Must return a hash with keys matching your defined `return_field`s

Examples:
  - Definition: [example](https://github.com/rmosolgo/graphql-relay-ruby/blob/120b750cf86f1eb5c9997b588f022b2ef3a0012c/spec/support/star_wars_schema.rb#L74-L93)
  - Mount on mutation type: [example](https://github.com/rmosolgo/graphql-relay-ruby/blob/120b750cf86f1eb5c9997b588f022b2ef3a0012c/spec/support/star_wars_schema.rb#L111)

## Todo

- [ ] Fix `Node.create` -- make it return one object which exposes useful info

## More Resources

- [`graphql`](https://github.com/rmosolgo/graphql-ruby) Ruby gem
- [`graphql-relay-js`](https://github.com/graphql/graphql-relay-js) JavaScript helpers for GraphQL and Relay
