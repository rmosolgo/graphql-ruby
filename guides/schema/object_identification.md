---
layout: guide
doc_stub: false
search: true
title: Object Identification
section: Schema
desc: Working with unique global IDs
index: 8
---

Some GraphQL features use unique IDs to load objects:

- the `node(id:)` field looks up objects by ID
- any arguments with `loads:` configurations look up objects by ID

To use these features, you must provide a function for generating UUIDs and fetching objects with them. In your schema, define `self.id_from_object` and `self.object_from_id`:

```ruby
class MySchema < GraphQL::Schema
  def self.id_from_object(object, type_definition, query_ctx)
    # Generate a unique string ID for `object` here
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  def self.object_from_id(global_id, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
end
```

## Node interface

One requirement for Relay's object management is implementing the `"Node"` interface.

To implement the node interface, add {{ "GraphQL::Types::Relay::Node" | api_doc }} to your definition:

```ruby
class Types::PostType < GraphQL::Schema::Object
  # Implement the "Node" interface for Relay
  implements GraphQL::Types::Relay::Node
  # ...
end
```

To tell GraphQL how to resolve members of the `Node` interface, you must also define `Schema.resolve_type`:

```ruby
class MySchema < GraphQL::Schema
  # You'll also need to define `resolve_type` for
  # telling the schema what type Relay `Node` objects are
  def self.resolve_type(type, obj, ctx)
    case obj
    when Post
      Types::PostType
    when Comment
      Types::CommentType
    else
      raise("Unexpected object: #{obj}")
    end
  end
end
```

## UUID fields

Nodes must have a field named `"id"` which returns a globally unique ID.

To add a UUID field named `"id"`, implement the {{ "GraphQL::Types::Relay::Node" | api_doc }} interface::

```ruby
class Types::PostType < GraphQL::Schema::Object
  implements GraphQL::Types::Relay::Node
end
```

This field will call the previously-defined `id_from_object` class method.

## `node` field (find-by-UUID)

You should also provide a root-level `node` field so that Relay can refetch objects from your schema. You can attach it like this:

```ruby
class Types::QueryType < GraphQL::Schema::Object
  # Used by Relay to lookup objects by UUID:
  # Add `node(id: ID!)
  include GraphQL::Types::Relay::HasNodeField
  # ...
end
```

## `nodes` field

You can also provide a root-level `nodes` field so that Relay can refetch objects by IDs:

```ruby
class Types::QueryType < GraphQL::Schema::Object
  # Fetches a list of objects given a list of IDs
  # Add `nodes(ids: [ID!]!)`
  include GraphQL::Types::Relay::HasNodesField
  # ...
end
```
