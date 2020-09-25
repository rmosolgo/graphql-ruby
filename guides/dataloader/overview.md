---
layout: guide
doc_stub: false
search: true
section: Dataloader
title: Overview
desc: Data loading in GraphQL
index: 0
redirect_from:
  - /schema/lazy_execution
---

Because GraphQL queries are very dynamic, GraphQL systems require a different approach to fetching data into your application. Here, we'll discuss the problem and solution at a conceptual level. Later, the {% internal_link "Using Dataloader", "/dataloader/usage" %} and {% internal_link "Custom Sources", "/dataloader/custom_sources" %} guides provide concrete implementation advice.

## Dynamic Data Requirements

When your application renders a predetermined HTML template or JSON payload, you can customize your SQL query for minimum overhead and maximum performance. But, in GraphQL, the response is highly dependent on the incoming query. When clients are sending custom queries, you can't hand-tune database queries!

For example, imagine this incoming GraphQL query:

```ruby
films(first: 10) {
  director { name }
}
```

If the `director` field is implemented with a Rails `belongs_to` association, it will be an N+1 situation by default. As each `Film`'s fields are resolved, they will each dispatch a SQL query:

```SQL
SELECT * FROM directors WHERE id = 1;
SELECT * FROM directors WHERE id = 2;
SELECT * FROM directors WHERE id = 3;
...
```

This is inefficient because we make _many_ round-trips to the database. So, how can we improve our GraphQL system to use that more-efficient query?

(Although this example uses SQL, the same issue applies to any external service that your application might fetch data from, for example: Redis, Memcached, REST APIs, GraphQL APIs, search engines, RPC servers.)

## Batching External Service Calls

The solution is to dispatch service calls in _batches_. As a GraphQL query runs, you can gather up information, then finally dispatch a call. In the example above, we could _batch_ those SQL queries into a single query:

```SQL
SELECT * FROM directors WHERE id IN(1,2,3,...);
```

This technique was demonstrated in [graphql/dataloader](https://github.com/graphql/dataloader) and implemented in Ruby by [shopify/graphql-batch](https://github.com/shopify/graphql-batch) and [exaspark/batch-loader](https://github.com/exAspArk/batch-loader/). Now, GraphQL-Ruby has a built-in implementation, {{ "GraphQL::Dataloader" | api_doc }}.

## GraphQL::Dataloader

{{ "GraphQL::Dataloader" | api_doc }} is an implementation of batch loading for GraphQL-Ruby. It consists of several components:

- {{ "GraphQL::Dataloader" | api_doc }} instances, which manage a cache of sources during query execution
- {{ "GraphQL::Dataloader::Source" | api_doc }}, a base class for batching calls to data layers and caching the results
- {{ "GrpahQL::Execution::Lazy" | api_doc }}, a Promise-like object which can be chained with `.then { ... }` or zipped with `GraphQL::Execution::Lazy.all(...)`.

Check out the {% internal_link "Usage guide", "dataloader/usage" %} to get started with it.
