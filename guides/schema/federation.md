---
layout: guide
doc_stub: false
search: true
section: Schema
title: Federation
desc: Exposing a GraphQL-Ruby schema as a federation subgraph
index: 9
---

GraphQL-Ruby can expose a schema as a GraphQL federation subgraph with `GraphQL::Federation`. It adds the federation directives and the subgraph fields used by federation gateways:

- `_service { sdl }` returns this subgraph's SDL
- `_entities(representations:)` resolves entity references by `__typename` and key fields

`GraphQL::Federation` implements subgraph behavior only. It doesn't compose subgraphs or route client operations between them.

## Setup

Load federation support before defining types that use federation helpers:

```ruby
# For example, in config/application.rb, an initializer, or your base GraphQL type file:
require "graphql/federation"
```

Then, install it in your schema after configuring the query root:

```ruby
class MySchema < GraphQL::Schema
  query Types::Query

  use GraphQL::Federation
end
```

Federation adds the `_service` field to the query root. If the schema has entity types, it also adds `_entities` and the `_Entity` union.

## Entities

An entity is an object type with at least one `key`:

```ruby
class Types::Manufacturer < Types::BaseObject
  key "id"

  field :id, ID, null: false
  field :name, String, null: false

  def self.resolve_reference(representation, context:)
    ::Manufacturer.find_by(id: representation["id"])
  end
end

class Types::Product < Types::BaseObject
  key "id"

  field :id, ID, null: false
  field :manufacturer, Types::Manufacturer, null: true
  field :name, String, null: false

  def self.resolve_reference(representation, context:)
    ::Product.find_by(id: representation["id"])
  end

  def manufacturer
    object.manufacturer
  end
end
```

`resolve_reference` receives a representation from the gateway, for example:

```ruby
{ "__typename" => "Product", "id" => "123" }
```

It should return the application object for that representation, or `nil` if no object should be returned. It may accept `context:` as a keyword argument, a second positional `context` argument, or only the representation.

Entity types must be reachable from the schema. If an entity isn't returned by any field, add it with `orphan_types`:

```ruby
class MySchema < GraphQL::Schema
  query Types::Query
  orphan_types Types::Product
  use GraphQL::Federation
end
```

## Queries

A gateway can resolve entities by sending representations to `_entities`:

```graphql
query($representations: [_Any!]!) {
  _entities(representations: $representations) {
    __typename
    ... on Product {
      id
      name
    }
    ... on Manufacturer {
      id
      name
    }
  }
}
```

with variables:

```json
{
  "representations": [
    { "__typename": "Product", "id": "123" },
    { "__typename": "Manufacturer", "id": "1" }
  ]
}
```

That single operation resolves both entity representations. This is the subgraph-level mechanism a gateway uses when one client query needs data from several entity types.

## Testing with curl

If your app serves GraphQL at `/graphql`, you can query the federation fields directly with `curl`.

Check the subgraph SDL:

```bash
curl http://localhost:3000/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ _service { sdl } }"}'
```

The response includes the SDL string:

```json
{
  "data": {
    "_service": {
      "sdl": "type Product @key(fields: \"id\") { ... }"
    }
  }
}
```

Resolve entity representations together:

```bash
curl http://localhost:3000/graphql \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "query($representations: [_Any!]!) { _entities(representations: $representations) { __typename ... on Product { id name manufacturer { id name } } ... on Manufacturer { id name } } }",
    "variables": {
      "representations": [
        { "__typename": "Product", "id": "123" },
        { "__typename": "Manufacturer", "id": "1" }
      ]
    }
  }'
```

That request calls each type's `resolve_reference` hook and returns the selected fields in the same response:

```json
{
  "data": {
    "_entities": [
      {
        "__typename": "Product",
        "id": "123",
        "name": "Table",
        "manufacturer": {
          "id": "1",
          "name": "Acme"
        }
      },
      {
        "__typename": "Manufacturer",
        "id": "1",
        "name": "Acme"
      }
    ]
  }
}
```

## SDL

Federation exposes the subgraph SDL through `_service`:

```graphql
{
  _service {
    sdl
  }
}
```

The SDL includes your schema's federation annotations, for example `@key`, `@external`, and `@requires`, but omits the automatically-added `_service`, `_entities`, `_Service`, `_Entity`, `_Any`, and `_FieldSet` definitions.

You can also get the same SDL from Ruby:

```ruby
MySchema.federation_sdl
```

## Directives

Federation provides these schema directives:

- `@key`
- `@external`
- `@requires`
- `@provides`
- `@extends`
- `@shareable`
- `@inaccessible`
- `@override`
- `@tag`
- `@interfaceObject`

For common directives, GraphQL-Ruby provides Ruby helpers:

```ruby
class Types::Product < Types::BaseObject
  key "id"
  key "sku package", resolvable: false
  federation_extends
  shareable
  tag "inventory"

  field :sku, String, null: false do
    external
  end

  field :shipping_estimate, Integer, null: true do
    requires "sku"
  end

  field :manufacturer, Types::Manufacturer, null: true do
    provides "name"
  end

  field :price, Integer, null: true do
    override_from "Products", label: "percent(10)"
  end
end
```

For less common cases, attach the directive class directly:

```ruby
class Types::Product < Types::BaseObject
  directive GraphQL::Federation::Directives::Inaccessible
end
```

Directives are printed in SDL dumps from `Schema.to_definition` and `Schema.federation_sdl`.
