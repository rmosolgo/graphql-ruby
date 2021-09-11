---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Caching Results
desc: Configuration options for caching objects and fields
index: 2
---

`GraphQL::Enterprise::ObjectCache` supports several different caching configurations for objects and fields. To get started, include the extension in your base object class and base field class and use `cacheable(...)` to set up the default cache behavior:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  include GraphQL::Enterprise::ObjectCache::ObjectIntegration
  cacheable(...) # see below
  # ...
end
```

```ruby
# app/graphql/types/base_field.rb
class Types::BaseField < GraphQL::Schema::Field
  include GraphQL::Enterprise::ObjectCache::FieldIntegration
  cacheable(...) # see below
  # ...
end
```

Field caching can be configured per-field, too, for example:

```ruby
field :latest_update, Types::Update, null: false, cacheable: { ttl: 60 }

field :random_number, Int, null: false, cacheable: false
```

Only _queries_ are cached. `ObjectCache` skips mutations and subscriptions altogether.

## `cacheable(true|false)`

`cacheable(true)` means that the configured type or field may be stored in the cache until its cache fingerprint changes. It also defaults to `public: true`, meaning that cached values may be shared among all clients. See [`public: false`](#public-false) below to cache different values for each client.

`cacheable(false)` disables caching for the configured type or field. Any query that includes this type or field will neither check for an already-cached value nor update the cache with its result.

## `public: false`

`cacheable(public: false)` means that a type or field may be _cached_, but {% internal_link "`Schema.private_context_fingerprint_for(ctx)`", "/object_cache/schema_setup#context-fingerprint" %} should be included in its cache key. In practice, this means that each client can have its own cached responses.

Any query that contains a `cacheable(public: false)` type or field will use a private cache key.

## `ttl:`

`cacheable(ttl: seconds)` expires any cached value after the given number of seconds, regardless of cache fingerprint. `ttl:` shines in two cases:

- objects that can't reliably generate a fingerprint value (for example, they have no `.updated_at` timestamp). In this case, a conservative `ttl` may be the only option for cache expiration.
- or, root-level fields that should be expired after a certain amount of time. The root-level `Query` often has _no_ backing object, so it won't have a cache fingerprint, either. Adding `cacheable: { ttl: ... }` to root level fields will provide some caching along with a guarantee about when they'll be expired.

Under the hood, `ttl:` is implemented with Redis's `EXPIRE`.
