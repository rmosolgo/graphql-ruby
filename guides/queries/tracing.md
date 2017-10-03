---
title: Tracing
layout: guide
search: true
section: Queries
desc: Observation hooks for execution
index: 11
experimental: true
---

{{ "GraphQL::Tracing" | api_doc }} provides a `.trace` hook to observe events from the GraphQL runtime.

A tracer must implement `.trace`, for example:

```ruby
class MyCustomTracer
  def self.trace(key, data)
    # do stuff with key & data
    yield
  end
end
```

`.trace` is called with:

- `key`: the event happening in the runtime
- `data`: a hash of metadata about the event
- `&block`: the event itself, it must be `yield`ed and the value must be returned

To run a tracer for __every query__, add it to the schema with `tracer`:

```ruby
# Run `MyCustomTracer` for all queries
MySchema = GraphQL::Schema.define do
  tracer(MyCustomTracer)
end
```

Or, to run a tracer for __one query only__, add it to `context:` as `tracers: [...]`, for example:

```ruby
# Run `MyCustomTracer` for this query
MySchema.execute(..., context: { tracers: [MyCustomTracer]})
```

For a full list of events, see the {{ "GraphQL::Tracing" | api_doc }} API docs.

## ActiveSupport::Notifications

You can emit events to `ActiveSupport::Notifications` with an experimental tracer, `ActiveSupportNotificationsTracing`.

To enable it, install the tracer:

```ruby
# Send execution events to ActiveSupport::Notifications
MySchema = GraphQL::Schema.define do
  tracer GraphQL::Tracing::ActiveSupportNotificationsTracing
end
```
