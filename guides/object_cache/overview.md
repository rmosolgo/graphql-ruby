# GraphQL ObjectCache

`GraphQL::Enterprise::ObjectCache` is an application-level cache for GraphQL-Ruby servers. It works by storing a [_cache fingerprint_ for each object](/object_cache/schema_setup#object-fingerprint) in a query, then serving a cached response as long as those fingerprints don't change. The cache can also be customized with [TTLs](/object_cache/caching#ttl).

## Why?

`ObjectCache` can greatly reduce GraphQL response times by serving cached responses when the underlying data for a query hasn't changed.

Usually, a GraphQL query alternates between data fetching and calling application logic:


![GraphQL-Ruby profile, without caching](/object_cache/query-without-cache.png)


But with `ObjectCache`, it checks the cache first, returning a cached response if possible:

![GraphQL-Ruby profile, with ObjectCache](/object_cache/query-with-cache.png)

This reduces latency for clients and reduces the load on your database and application server.

## How

Before running a query, `ObjectCache` creates a fingerprint for the query using [GraphQL::Query#fingerprint](rdoc-ref:GraphQL::Query#fingerprint) and [`Schema.context_fingerprint_for(ctx)`](/object_cache/schema_setup#context-fingerprint). Then, it checks the backend for a cached response which matches the fingerprint.

If a match is found, the `ObjectCache` fetches the objects previously visited by this query. Then, it compares the current fingerprint of each object ot the one in the cache and checks `.authorized?` for that object. If the fingerprints all match and all objects pass authorization checks, then the cached response returned. (Authorization checks can be [disabled](/object_cache/schema_setup#disabling-reauthorization).)

If there is no cached response or if the fingerprints don't match, then the incoming query is re-evaluated. While it's executed, `ObjectCache` gathers the IDs and fingerprints of each object it encounters. When the query is done, the result and the new object fingerprints are written to the cache.

## Setup

To get started with the object cache:

- [Prepare the schema](/object_cache/schema_setup)
- Set up a [Redis backend](/object_cache/redis) or [Memcached backend](/object_cache/memcached)
- [Configure types and fields for caching](/object_cache/caching)
- Check out the [runtime considerations](/object_cache/runtime_considerations)
