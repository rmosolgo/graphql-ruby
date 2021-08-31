---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: GraphQL ObjectCache
desc: A server-side cache for GraphQL-Ruby
index: 0
---

`GraphQL::Enterprise::ObjectCache` is an application-level cache for GraphQL-Ruby servers. It works by storing the updated-at timestamp for each object in a query, then serving a cached response as long as those timestamps don't change. The cache can also be customized with TTLs.

## Why?

`ObjectCache` can greatly reduce GraphQL response times by serving cached responses when the underlying data for a query hasn't changed.

![GraphQL-Ruby profile, with and without caching](#todo)

## How

Before running a query, `ObjectCache` creates a fingerprint for the query using {{ "GraphQL::Query#fingerprint" | api_doc }} and {% internal_link "Schema.context_fingerprint_for(ctx)", "/object_cache/schema#context-fingerprint" %}. Then, it checks the backend for a cached response which matches the fingerprint. If a match is found, the `ObjectCache` fetches the objects previously visited by this query and compares their current fingerprints to the ones in the cache. If the fingerprints all match, then the cached response returned.

If there is no cached response or if the fingerprints don't match, then the incoming query is re-evaluated. While it's executed, `ObjectCache` gathers the IDs and fingerprints of each object it encounters. When the query is done, the result and the new object fingerprints are written to the cache.

## Setup

To get started with the object cache, you need to:

- Add it to your schema
- Prepare Redis to store
- Configure your object types for caching
