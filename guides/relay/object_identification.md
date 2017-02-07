---
title: Relay — Object Identification
---

Relay uses [global object identification](https://facebook.github.io/relay/docs/graphql-object-identification.html) support some of its features:

- __Caching__: Unique IDs are used as primary keys in Relay's client-side cache.
- __Refetching__: Relay uses unique IDs to refetch objects when it determines that its cache is stale. (It uses the `Query.node` field to refetch objects.)

### Defining UUIDs

You must provide a function for generating UUIDs and fetching objects with them. In your schema, define `id_from_object` and `object_from_id`:

```ruby
MySchema = GraphQL::Schema.define do
  id_from_object ->(object, type_definition, query_ctx) {
    # Call your application's UUID method here
    # It should return a string
    MyApp::GlobalId.encrypt(object.class.name, object.id)
  }

  object_from_id ->(id, query_ctx) {
    class_name, item_id = MyApp::GlobalId.decrypt(id)
    # "Post" => Post.find(id)
    Object.const_get(class_name).find(item_id)
  }
end
```

An unencrypted ID generator is provided in the gem. It uses `Base64` to encode values. You can use it like this:

```ruby
MySchema = GraphQL::Schema.define do
  # Create UUIDs by joining the type name & ID, then base64-encoding it
  id_from_object ->(object, type_definition, query_ctx) {
    GraphQL::Schema::UniqueWithinType.encode(type_definition.name, object.id)
  }

  object_from_id ->(id, query_ctx) {
    type_name, item_id = GraphQL::Schema::UniqueWithinType.decode(id)
    # Now, based on `type_name` and `id`
    # find an object in your application
    # ....
  }
end
```

### UUID fields

To participate in Relay's caching and refetching, objects must do two things:

- Implement the `"Node"` interface
- Define an `"id"` field which returns a UUID

To implement the node interface, include `GraphQL::Relay::Node.interface` in your list of interfaces:

```ruby
PostType = GraphQL::ObjectType.define do
  name "Post"
  # Implement the "Node" interface for Relay
  interfaces [GraphQL::Relay::Node.interface]
  # ...
end
```

To add a UUID field named `"id"`, use the `global_id_field` helper:

```ruby
PostType = GraphQL::ObjectType.define do
  name "Post"
  # ...
  # `id` exposes the UUID
  global_id_field :id
  # ...
end
```

Now, `PostType` can participate in Relay's UUID-based features.

### `node` field (find-by-UUID)

You should also provide a root-level `node` field so that Relay can refetch objects from your schema. It is provided as `GraphQL::Relay::Node.field`, so you can attach it like this:

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Used by Relay to lookup objects by UUID:
  field :node, GraphQL::Relay::Node.field
  # ...
end
```

### `nodes` field

You can also provide a root-level `nodes` field so that Relay can refetch objects by IDs. Similarly, it is provided as `GraphQL::Relay::Node.plural_field`:

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Fetches a list of objects given a list of IDs
  field :nodes, GraphQL::Relay::Node.plural_field
  # ...
end
```
