---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Schema Setup
desc: Prepare your schema to serve cached responses
index: 1
---

To prepare the schema to serve cached responses, you have to add `GraphQL::Enterprise::ObjectCache` and implement a few hooks.

### Add the Cache

In your schema, add `use GraphQL::Enterprise::ObjectCache, redis: ...`:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Enterprise::ObjectCache, redis: CACHE_REDIS
end
```

See the {% internal_link "Redis guide", "/cache/redis" %} for details about configuring cache storage.

Additionally, it accepts some options for customizing how introspection is cached:

- `cache_introspection: { public: false }` to use `public: false` for all introspection fields. Use this if you hide schema members for some clients.
- `cache_introspection: false` to completely disable caching on introspection fields.

### Context Fingerprint

Additionally, you should implement `def self.private_context_fingerprint_for(context)` to return a string identifying the private scope of the given context. This method will be called whenever a query includes a `public: false` field. For example:

```ruby
class MySchema < GraphQL::Schema
  # ...
  def self.private_context_fingerprint_for(context)
    viewer = context[:viewer]
    if viewer.nil?
      # This should never happen, but just in case:
      raise("Invariant: No viewer in context! Can't create a private context fingerprint" )
    end

    # include permissions in the fingerprint so that if the viewer's permissions change, the cache will be invalidated
    permission_fingerprint = viewer.team_memberships.map { |tm| "#{tm.team_id}/#{tm.permission}" }.join(":")

    "user:#{viewer.id}:#{permission_fingerprint}"
  end
end
```

Whenever queries including `public: false` are cached, the private context fingerprint will be part of the cache key, preventing responses from being shared between different viewers.

The returned String should reflect any aspects of `context` that, if changed, should invalidate the cache. For example, if a user's permission level or team memberships change, then any previously-cached responses should be ignored.

### Object Identification

`ObjectCache` depends on object identification hooks used elsewhere in GraphQL-Ruby:

- `def self.id_from_object(object, type, context)` which returns a globally-unique String id for `object`
- `def self.object_from_id(id, context)` which returns the application object for the given globally-unique `id`
- `def self.resolve_type(abstract_type, object, context)` which returns a GraphQL object type definition to use for `object`

Additionally, `ObjectCache` uses `def self.object_fingerprint_for(object, context)`, which returns a string for `object`, to use as a cache key. If the method returns `nil`, `ObjectCache` doesn't cache the object (or the query it's part of). The default implementation tries `.cache_key_with_version` and `.to_param` (following Rails conventions) or returns `nil` if those aren't implemented.
