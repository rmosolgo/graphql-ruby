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

Now, {{ "GraphQL::Dataloader::AsyncDataloader" | api_doc }} will create `Async::Task` instances instead of plain `Fiber`s and the `async` gem will manage parallelism.

For a demonstration of this behavior, see: [https://github.com/rmosolgo/rails-graphql-async-demo](https://github.com/rmosolgo/rails-graphql-async-demo)

## Rails

For Rails, you'll also want to configure Rails to use Fibers for isolation:

```ruby
class Application < Rails::Application
  # ...
  config.active_support.isolation_level = :fiber
end
```

## Fiber Limit

By default, `AsyncDataloader` spins up 10 Fibers to work through GraphQL execution. Beyond this, it will add Fibers for resolving any `Dataloader::Source`s. You can customize the execution queue size with `working_queue_size: ...`, for example:

```ruby
use GraphQL::Dataloader::AsyncDataloader, working_queue_size: 100
```

You can pass `working_queue_size: nil` to remove any limit on active Fibers.
