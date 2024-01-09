---
layout: guide
search: true
section: Dataloader
title: Async Source Execution
desc: Using AsyncDataloader to fetch external data in parallel
index: 5
---

`AsyncDataloader` will run {{ "GraphQL::Dataloader::Source#fetch" | api_doc }} calls in parallel, so that external service calls (like database queries or network calls) don't have to wait in a queue.

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

_You can also implement {% internal_link "manual parallelism", "/dataloader/parallelism" %} using `dataloader.yield`._

## Rails

For Rails, you'll need **Rails 7.1**, which properly supports fiber-based concurrency, and you'll also want to configure Rails to use Fibers for isolation:

```ruby
class Application < Rails::Application
  # ...
  config.active_support.isolation_level = :fiber
end
```

## Other Options

You can also manually implement parallelism with Dataloader. See the {% internal_link "Dataloader Parallelism", "/dataloader/parallelism" } guide for details.
