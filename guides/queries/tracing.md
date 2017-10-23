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

## Monitoring

Several monitoring platforms are supported out-of-the box by GraphQL-Ruby (see platforms below).

Leaf fields are _not_ monitored (to avoid high cardinality in the metrics service).

Implementations are based on {{ "Tracing::PlatformTracing" | api_doc }}.

## Appsignal

To add [AppSignal](https://appsignal.com/) instrumentation:

```ruby
MySchema = GraphQL::Schema.define do
  use(GraphQL::Tracing::AppsignalTracing)
end
```

<div class="monitoring-img-group">
  {{ "/queries/appsignal_example.png" | link_to_img:"appsignal monitoring" }}
</div>

## New Relic

To add [New Relic](https://newrelic.com/) instrumentation:

```ruby
MySchema = GraphQL::Schema.define do
  use(GraphQL::Tracing::NewRelicTracing)
end
```


<div class="monitoring-img-group">
  {{ "/queries/new_relic_example.png" | link_to_img:"new relic monitoring" }}
</div>

## Scout

To add [Scout APM](https://scoutapp.com/) instrumentation:

```ruby
MySchema = GraphQL::Schema.define do
  use(GraphQL::Tracing::ScoutTracing)
end
```

<div class="monitoring-img-group">
  {{ "/queries/scout_example.png" | link_to_img:"scout monitoring" }}
</div>

## Skylight

To add [Skylight](http://skylight.io) instrumentation:

```ruby
MySchema = GraphQL::Schema.define do
  use(GraphQL::Tracing::SkylightTracing)
end
```


<div class="monitoring-img-group">
  {{ "/queries/skylight_example.png" | link_to_img:"skylight monitoring" }}
</div>
