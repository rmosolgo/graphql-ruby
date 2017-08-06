---
layout: guide
search: true
section: Schema
title: Implementation API
desc: Alternative schema implementation API
experimental: true
---

This covers a new, experimental API for building a GraphQL system. It has two parts:

- Define the structure in a `.graphql` file
- Define the behavior in a a set of Ruby classes
- Combine them using `Schema.from_definition`

## Structure

Describe your GraphQL schema with the [GraphQL IDL](http://graphql.org/learn/schema/#type-language) in a single `.graphql` file, for example:

```graphql
# $ cat app/graphql/schema.graphql
type Query {
  highScorer: Player
  players: [Player]
  player(id: ID!): Player
}

type Player {
  name: String
  highScore: Int
}
```

## Behavior

Objects in your schema can be customized with implementation classes. Implementation classes extend from `GraphQL::Object`, `GraphQL::Union`, `GraphQL::Interface,` or `GraphQL::Scalar`.

- [] TODO what namespace to recommend to rails users?

### Objects

`GraphQL::Object` subclasses are initialized with two attributes:

- `object` refers to the application value being exposed
- `context` refers to the `context:` values

Fields are implemented by:

- Calling a method on the implementation; or
- Calling a method on `object`

GraphQL arguments are passed to the method a keyword arguments.

GraphQL fields in `camelCase` are converted to `underscore_case` method names.

Given a GraphQL type like this:

```graphql
type PlayingCard {
  suit: Suit
  number: Int
  isFacecard: Boolean
  # Returns true if this card's number is greater than `otherNumber`
  isGreaterThan(otherNumber: Int!): Boolean
}
```

```ruby
class Graph::PlayingCard < GraphQL::Object
  # isFacecard => is_facecard
  def is_facecard
    object.number > 10
  end

  # suit & number are delegated to `object` by default

  # Arguments are passed as keyword args;
  # argument names are also camelized
  def is_greater_than(other_number:)
    object.number > number
  end
end
```

### Unions, Interfaces

Abstract types may be undefined or they _may_ implement `.resolve_type` to override {{ "Schema#resolve_type" | api_doc }}.

```ruby
class Graph::Playable < GraphQL::Union
  def resolve_type
    if object.respond_to?(:suit)
      Graph::Card
    elsif object.respond_to?(:dots)
      Graph::Dice
    else
      raise "Unexpected playable: #{object}"
    end
  end
end
```

### Scalars

Scalars are initialized with `object` and `context`. `object` may be _either_ an incoming GraphQL value or an outgoing Ruby value.

Scalars must implement:

- `#parse`, for turning `object` into an application-ready Ruby value
- `#serialize`, for turning `object` into a GraphQL primitive (eg, `String`, `Int`)

```ruby
# scalar Datetime
class Graph::Datetime < GraphQL::Scalar
  # `object` is an incoming GraphQL value, maybe:
  # - String, if coming from the GraphQL document or HTTP query string
  # - Other Ruby value, if coming from Ruby code
  def parse
    case object
    when String
      object.strptime("%Y-%m-%d %H:%M:%D")
    when DateTime
      object
    else
      raise "Unexpected input for Datetime: #{object}"
    end
  end

  # Turn a Ruby value into a GraphQL value.
  # May be any type returned by fields in the schema.
  def serialize
    object.strftime("%Y-%m-%d %H:%M:%D")
  end
end
```

## Combine Them

Build a schema by loading the structure from a file and passing the namespace as `implementation:`

```ruby
MySchema = GraphQL::Schema.from_definition(
  "app/graphql/my_schema.graphql",
  implementation: Graph,
)
```
