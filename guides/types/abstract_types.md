---
layout: guide
search: true
section: Types
title: Interface and Union Types
desc: GraphQL's interface and union types contain one or more objects with something in common
index: 3
---

## Type Resolution

When we have a member of an interface or union, which object type should we use? Your GraphQL schema may need help from you, which you can provide as `resolve_type(obj, ctx)`.

Provide `resolve_type` as an object that responds to `#call`, for example, a `Proc` literal:

```ruby
GraphQL::Schema.define do
  resolve_type ->(obj, ctx) { ... }
end
```

or, a module:

```ruby
module ResolveType
  def self.call(obj, ctx)
    # ...
  end
end


GraphQL::Schema.define do
  resolve_type ResolveType
end
```

## Orphan Types

The schema builds its type system by traversing its data entry points. In some cases, types should be present in the schema but aren't available via traversal, so you have to add them yourself.

The clearest case of this is when a type implements an interface, but isn't a return type of any other field. Since it's not the return type of a field, it might not be found by traversal, so you can add it in `orphan_types`:

```ruby
GraphQL::Schema.define do
  # ...
  # Make sure these types are present in the schema:
  orphan_types [AudioType, VideoType, ImageType]
end
```

It's OK to add a type to `orphan_types` even if it's already in the schema.
