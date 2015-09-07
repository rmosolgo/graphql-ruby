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

You should create `GraphQL::Relay::GlobalNodeIdentification` helper by defining `object_from_id(global_id)` & `type_from_object(object)`. The resulting object provides ID resultion methods, a find-by-global-id field and a node interface. [Example](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L9-L18)

ObjectTypes should implement that interface with the `global_id_field` helper: [Example](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L30-L31)

You should attach the field to your query type: [Example](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L121)

### Connections

Connections will provide arguments, pagination and `pageInfo` for `Array`s or `ActiveRecord::Relation`s. You can use the `connection` definition helper.

Then, implement the field. It's different than a normal field:
  - use the `connection` helper to define it, instead of `field`
  - Call `#connection_type` on an `ObjectType` for the field's return type (eg, `ShipType.connection_type`)

Examples:

- [Connection with custom arguments](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L51-L63)
- [Connection with a different name than the underlying property](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L77)

You can also add custom fields to connection objects: [Example](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L36-L43)

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
  - Definition: [example](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L90)
  - Mount on mutation type: [example](https://github.com/rmosolgo/graphql-relay-ruby/blob/master/spec/support/star_wars_schema.rb#L127)

## Todo

- Show how to replace default connection implementations with custom ones

## More Resources

- [GraphQL Slack](graphql-slack.herokuapp.com), come join us in the `#ruby` channel!
- [`graphql`](https://github.com/rmosolgo/graphql-ruby) Ruby gem
- [`graphql-relay-js`](https://github.com/graphql/graphql-relay-js) JavaScript helpers for GraphQL and Relay
