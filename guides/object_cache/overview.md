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

`GraphQL::Enterprise::ObjectCache` is an application-level cache for GraphQL-Ruby servers. It works by storing a {% internal_link "_cache fingerprint_ for each object", "/object_cache/schema_setup#object-fingerprint" %} in a query, then serving a cached response as long as those fingerprints don't change. The cache can also be customized with {% internal_link "TTLs", "/object_cache/caching#ttl" %}.

## Why?

`ObjectCache` can greatly reduce GraphQL response times by serving cached responses when the underlying data for a query hasn't changed.

Usually, a GraphQL query alternates between data fetching and calling application logic:


{{ "/object_cache/query-without-cache.png" | link_to_img:"GraphQL-Ruby profile, without caching" }}


But with `ObjectCache`, it checks the cache first, returning a cached response if possible:

{{ "/object_cache/query-with-cache.png" | link_to_img:"GraphQL-Ruby profile, with ObjectCache" }}

This reduces latency for clients and reduces the load on your database and application server.

## How

Before running a query, `ObjectCache` creates a fingerprint for the query using {{ "GraphQL::Query#fingerprint" | api_doc }} and {% internal_link "`Schema.context_fingerprint_for(ctx)`", "/object_cache/schema_setup#context-fingerprint" %}. Then, it checks the backend for a cached response which matches the fingerprint. If a match is found, the `ObjectCache` fetches the objects previously visited by this query and compares their current fingerprints to the ones in the cache. If the fingerprints all match, then the cached response returned.

If there is no cached response or if the fingerprints don't match, then the incoming query is re-evaluated. While it's executed, `ObjectCache` gathers the IDs and fingerprints of each object it encounters. When the query is done, the result and the new object fingerprints are written to the cache.

## Setup

To get started with the object cache:

- {% internal_link "Prepare the schema", "/object_cache/schema_setup" %}
- {% internal_link "Set up a Redis backend", "/object_cache/redis" %}
- {% internal_link "Configure types and fields for caching", "/object_cache/caching" %}
- Check out the {% internal_link "runtime considerations", "/object_cache/runtime_considerations" %}
