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
  def trace(key, data)
    # do stuff with key & data
    yield
  end
end
```

`.trace` is called with:

- `key`: the event happening in the runtime
- `data`: a hash of metadata about the event
- `&block`: the event itself, it must be `yield`ed and the value must be returned

To install a tracer, use `GraphQL::Tracing.install`:

```ruby
GraphQL::Tracing.install(MyCustomTracer.new)
```

To uninstall, use `GraphQL::Tracing.install(nil)`.

For a full list of events, see the {{ "GraphQL::Tracing" | api_doc }} API docs.

## ActiveSupport::Notifications

You can emit events to `ActiveSupport::Notifications` with an experimental tracer, `ActiveSupportNotificationsTracing`.

To enable it, install the tracer:

```ruby
# Send execution events to ActiveSupport::Notifications
GraphQL::Tracing.install(
  GraphQL::Tracing::ActiveSupportNotificationsTracing
)
```
