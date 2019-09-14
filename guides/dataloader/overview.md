---
layout: guide
doc_stub: false
search: true
section: Dataloader
title: Overview
desc: Data loading in GraphQL
index: 0
---

Because GraphQL queries are very dynamic, GraphQL systems require a different approach to fetching data into your application. Here, we'll discuss the problem and solution at a conceptual level. Later, the {% internal_link "Using Dataloader", "/dataloader/usage" %} and {% internal_link "Custom Loaders", "/dataloader/custom_loaders" %} guides provide concrete implementation advice.

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

This technique was demonstrated in [graphql/dataloader](https://github.com/graphql/dataloader) and implemented in Ruby by [shopify/graphql-batch](https://github.com/shopify/graphql-batch) and [exaspark/batch-loader](https://github.com/exAspArk/batch-loader/). Now, GraphQL-Ruby has a built-in implementation, {{ "GraphQL::Dataloader" | api_doc }}. Learn how to use it in the {% internal_link "usage guide", "/dataloader/usage" %}.
