---
layout: guide
search: true
section: Dataloader
title: Parallel Data Loading for GraphQL
desc: Using AsyncDataloader to fetch external data in parallel
index: 5
---

`AsyncDataloader` will run GraphQL fields and Dataloader sources in parallel, so that external service calls (like database queries or network calls) don't have to wait in a queue.

To use `AsyncDataloader`, hook it up in your schema _instead of_ `GraphQL::Dataloader`:

```diff
- use GraphQL::Dataloader
+ use GraphQL::Dataloader::AsyncDataloader
```

__Also__, add [the `async` gem](https://github.com/socketry/async) to your project, for example:

```
bundle add async
```

That's it! Now, {{ "GraphQL::Dataloader::AsyncDataloader" | api_doc }} will create `Async::Task` instances instead of plain `Fiber`s and the `async` gem will manage parallelism.

For a demonstration of this behavior, see: [https://github.com/rmosolgo/rails-graphql-async-demo](https://github.com/rmosolgo/rails-graphql-async-demo)
