---
layout: guide
doc_stub: false
search: true
title: Object Identification
section: Relay
desc: Working with Relay-style global IDs
index: 0
---

Relay uses [global object identification](https://facebook.github.io/relay/graphql/objectidentification.htm) to support some of its features:

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
    # "Post" => Post.find(item_id)
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

### Node interface

One requirement for Relay's object management is implementing the `"Node"` interface.

To implement the node interface, include {{ "GraphQL::Relay::Node.interface" | api_doc }} in your list of interfaces:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  name "Post"
  # Implement the "Node" interface for Relay
  implements GraphQL::Relay::Node.interface
  # ...
end
```

To tell GraphQL how to resolve members of the `"Node"` interface, you must also define `Schema#resolve_type`:

```ruby
MySchema = GraphQL::Schema.define do
  # You'll also need to define `resolve_type` for
  # telling the schema what type Relay `Node` objects are
  resolve_type ->(type, obj, ctx) {
    case obj
    when Post
      Types::PostType
    when Comment
      Types::CommentType
    else
      raise("Unexpected object: #{obj}")
    end
  }
end
```

### UUID fields

Relay Nodes must have a field named `"id"` which returns a globally unique ID.

To add a UUID field named `"id"`, use the `global_id_field` helper:

```ruby
Types::PostType = GraphQL::ObjectType.define do
  name "Post"
  # ...
  # `id` exposes the UUID
  global_id_field :id
  # ...
end
```

This field will call the previously-defined `id_from_object` function.

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

Both of these fields may be customized using the usual definition block:

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"

  field :node, (GraphQL::Relay::Node.field do
    resolve ->(_, args, _) { # your own custom logic here }
  end)

  # ...
end
```
