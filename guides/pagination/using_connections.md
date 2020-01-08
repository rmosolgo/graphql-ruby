---
layout: guide
doc_stub: false
search: true
section: Pagination
title: Using Connections
desc: Pagination with GraphQL-Ruby's built-in connections
index: 2
---

GraphQL-Ruby ships with a few implementations of the {% internal_link "connection pattern", "pagination/connection_concepts" %} that you can use out of the box. They support Ruby Arrays, Mongoid, Sequel, and ActiveRecord.

## Adding the Plugin

GraphQL-Ruby 1.10.0 includes a new plugin for connections. It's more flexible and easier to customize. If it's not already added to your schema with `use ...`, add it:

```ruby
class MySchema < GraphQL::Schema
  # ...
  # Add the plugin for connection pagination
  use GraphQL::Pagination::Connections
```

## Make connection fields

Use `.connection_type` to generate a connection type for paginating over objects of a given type:

```ruby
field :items, Types::ItemType.connection_type, null: false
```

The generated return type will be called `ItemConnection`. Since it ends in `*Connection`, the `field(...)` will automatically be configured with `connection: true`. If the connection type's name doesn't end in `Connection`, you have to add that configuration yourself:

```ruby
# here's a custom type whose name doesn't end in "Connection", so `connection: true` is required:
field :items, Types::ItemConnectionPage, null: false, connection: true
```

The field will be given some arguments by default: `first`, `last`, `after`, and `before`.

## Return collections

With connection fields, you can return collection objects from fields or resolvers:

```ruby
def items
  object.items # => eg, returns an ActiveRecord Relation
end
```

The collection object (Array, Mongoid relation, Sequel dataset, ActiveRecord relation) will be automatically paginated with the provided arguments. Cursors will be generated based on the offset of nodes in the collection.

## Make custom connections
