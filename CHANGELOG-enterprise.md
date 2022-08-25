# graphql-enterprise

### Breaking Changes

### Deprecations

### New Features

### Bug Fix

# 1.1.11 (25 August 2022)

### Bug Fix

- ObjectCache: also update `delete` to handle more than 1000 objects in Lua

# 1.1.10 (19 August 2022)

### Bug Fix

- ObjectCache: read and write objects 1000-at-a-time to avoid overloading Lua scripts in Redis

# 1.1.9 (3 August 2022)

### New Features

- ObjectCache: Add a message to context when a type or field causes a query to be treated as "private"

### Bug Fix

- ObjectCache: skip the query analyzer when `context[:skip_object_cache]` is present

# 1.1.8 (1 August 2022)

### New Features

- ObjectCache: Add `ObjectType.cache_dependencies_for(object, context)` to customize dependencies for an object

### Bug Fix

- ObjectCache: Fix to make `context[:object_cache][:objects]` a Set
# 1.1.7 (28 July 2022)

### Bug Fix

- ObjectCache: remove needless `resolve_type` calls

# 1.1.6 (28 July 2022)

### Bug Fix

- ObjectCache: persist the type names of cached objects, pass them to `Schema.resolve_type` when validating cached responses.

# 1.1.5 (22 July 2022)

### New Features

- ObjectCache: add `cache_introspection: { ttl: ... }` for setting an expiration (in seconds) on introspection fields.

# 1.1.4 (19 March 2022)

### Bug Fix

- ObjectCache: don't create a cache fingerprint if the query is found to be uncacheable during analysis.

# 1.1.3 (3 March 2022)

### Bug Fix

- Changesets: Return an empty set when a schema doesn't use changesets #3972

# 1.1.2 (1 March 2022)

### New Features

- Changesets: Add introspection methods `Schema.changesets` and `Changeset.changes`

# 1.1.1 (14 February 2021)

### Bug Fix

- Changesets: don't require `context.schema` for plain-Ruby calls to introspection methods #3929

# 1.1.0 (24 November 2021)

### New Features

- Changesets: Add `GraphQL::Enterprise::Changeset`

# 1.0.1 (9 November 2021)

### Bug Fix

- Object Cache: properly handle invalid queries #3703

# 1.0.0 (13 October 2021)

### New Features

- Rate limiters: first release
- Object cache: first release
