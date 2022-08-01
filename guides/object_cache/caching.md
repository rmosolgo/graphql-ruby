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

`cacheable(true)` means that the configured type or field may be stored in the cache until its cache fingerprint changes. It also defaults to `public: false`, meaning that clients will _not_ share cached responses. See [`public:`](#public) below for more about this option.

`cacheable(false)` disables caching for the configured type or field. Any query that includes this type or field will neither check for an already-cached value nor update the cache with its result.

## `public:`

`cacheable(public: false)` means that a type or field may be _cached_, but {% internal_link "`Schema.private_context_fingerprint_for(ctx)`", "/object_cache/schema_setup#context-fingerprint" %} should be included in its cache key. In practice, this means that each client can have its own cached responses. Any query that contains a `cacheable(public: false)` type or field will use a private cache key.

`cacheable(public: true)` means that cached values from this type or field may be shared by _all_ clients. Use this for public-facing data which is the same for all viewers. Queries that include _only_ `public: true` types and fields will not include `Schema.private_context_fingerprint_for(ctx)` in their cache keys. That way their responses will be shared by all clients who request them.

## `ttl:`

`cacheable(ttl: seconds)` expires any cached value after the given number of seconds, regardless of cache fingerprint. `ttl:` shines in a few cases:

- Objects that can't reliably generate a fingerprint value (for example, they have no `.updated_at` timestamp). In this case, a conservative `ttl` may be the only option for cache expiration.
- Or, root-level fields that should be expired after a certain amount of time. The root-level `Query` often has _no_ backing object, so it won't have a cache fingerprint, either. Adding `cacheable: { ttl: ... }` to root level fields will provide some caching along with a guarantee about when they'll be expired.
- Or, list responses that may be difficult to invalidate properly (see below).

Under the hood, `ttl:` is implemented with Redis's `EXPIRE`.

## Caching lists and connections

Lists and connections require a little extra consideration. In order to effectively bust the cache, items that belong to the list of "parent" object should update the parent whenever they're modified in a way that changes the state of the list. For example, if there's a list of players on a team:

```graphql
{
  team { players { totalCount } }
}
```

None of the _specific_ `Player`s will be part of the cached response, but the `Team` will be. To properly invalidate the cache, the `Team`'s `updated_at` (or other cache key) should be updated whenever a `Player` is added or removed from the `Team`.

If a list may be sorted, then updates to `Player`s should also update the `Team` so that any sorted results in the cache are invalidated, too. Alternatively (or additionally), you could use a `ttl:` to expire cached results after a certain duration, just to be sure that results are eventually expired.

By default, connection-related objects (like `*Connection` and `*Edge` types) "inherit" cacheability from their node types. You can override this in your base classes as long as `GraphQL::Enterprise::ObjectCache::ObjectIntegration` is included in the inheritance chain somewhere.

## Caching Introspection

By default, introspection fields are considered _public_ for all queries. This means that they are considered cacheable and their results will be reused for any clients who request them. When {% internal_link "adding the ObjectCache to your schema", "/object_cache/schema_setup#add-the-cache", %}, you can provide some options to customize this behavior:

- `cache_introspection: { public: false, ... }` to use [`public: false`](#public) for all introspection fields. Use this if you hide schema members for some clients.
- `cache_introspection: false` to completely disable caching on introspection fields.
- `cache_introspection: { ttl: ..., ... }` to set a [ttl](#ttl) (in seconds) for introspection fields.

## Object Dependencies

By default, the `object` of a GraphQL Object type is used for caching the fields selected on that object. But, you can specify what object (or objects) should be used to check the cache by implementing `def self.cache_dependencies_for(object, context)` in your type definition. For example:

```ruby
class Types::Player
  def self.cache_dependencies_for(player, context)
    # we update the team's timestamp whenever player details change,
    # so ignore the `player` for caching purposes
    player.team
  end
end
```

Use this to:

- improve performance when caching lists of children that belong to a parent object
- register other objects with the ObjectCache when running a query. (`cacheable_object(obj)` or `def self.object_fingerprint_for` can also be used in this case.)

If this method returns an `Array`, each object in the array will be registered with the cache.
