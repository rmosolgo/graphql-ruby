---
layout: guide
search: true
section: Dataloader
title: Non-Blocking Data Loading for GraphQL
desc: Using Dataloader to fetch external data in parallel
index: 5
---

You can pass `nonblocking: true` to enable a non-blocking dataloader implementation based on Ruby 3's [`Fiber.scheduler`](https://ruby-doc.org/core-3.0.2/Fiber.html#class-Fiber-label-Non-blocking+Fibers) API:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Dataloader, nonblocking: true # enable parallel data loading
end
```

Alternatively, you can add a non-blocking `GraphQL::Dataloader` instance to `context[:dataloader]`:

```ruby
context = {
  # ...
  dataloader: GraphQL::Dataloader.new(nonblocking: true),
}
MySchema.execute(query_string, context: context, ...)
```


Additionally, you must __set up a Fiber scheduler__ with `Fiber.set_scheduler` before running your query:

```ruby
Fiber.set_scheduler(MySchedulerImplementation.new)
MySchema.execute(...)
```

The scheduler must implement [`Fiber::SchedulerImplementation`](https://ruby-doc.org/core-3.0.2/Fiber/SchedulerInterface.html). Existing implementations can be found at [Fiber Scheduler List](https://github.com/bruno-/fiber_scheduler_list).

- [`dsh0416/evt`](https://github.com/dsh0416/evt) supports several backends in `Evt::Scheduler`.
-  [`digital-fabric/libev_scheduler`](https://github.com/digital-fabric/libev_scheduler) contains `Libev::Scheduler`, built on [`libev`](http://pod.tst.eu/http://cvs.schmorp.de/libev/ev.pod), an event loop written in C. ⚠️ This _works_, but it was failing oddly on GitHub actions, so CI is turned off for it.
- ⚠️ [`socketry/async`](https://github.com/socketry/async) contains `Async::Scheduler`, but I haven't figured out how to make it work with `GraphQL::Dataloader` yet. Please update this doc if you know how to!
