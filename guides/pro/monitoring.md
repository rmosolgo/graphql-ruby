---
title: GraphQL::Pro — Instrumentation For Appsignal, New Relic, Scout and Skylight
---

`GraphQL::Pro` includes instrumentation for several platforms which add:

- Tracking queries by name
- Tracking field resolution
- Observing database calls during resolution  

By default, all fields in the schema are monitored, but you can [opt in or opt out](#opting-in-opting-out) on a type-by-type or field-by-field basis.

To add monitoring, provide one or more platform names to `monitoring(...)`:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  # Send query info to New Relic:
  monitoring(:new_relic)
  # Send info to Skylight and Scout:
  # monitoring(:skylight, :scout)
end
```

Supported platforms are:

- [Appsignal](#appsignal)
- [Datadog APM](#datadog)
- [New Relic](#new-relic)
- [Scout](#scout)
- [Skylight](#skylight)

## Opting in, Opting out

By default, `GraphQL::Pro` measures the resolution time of every field in the schema.

You can __opt out on a field- or type-basis__ by defining `monitoring(false)` in a field or type definition. For example:

```ruby
# Fields returning `Post` will _not_ be monitored
PostType = GraphQL::ObjectType.define do
  name "Post"
  monitoring false
  # ...
end

CommentType = GraphQL::ObjectType.define do
  # ...
  # This field won't be monitored:
  field :created_at, DateTimeType, monitoring: false

  # This field won't be monitored
  field :author, AuthorType do
    monitoring false
    resolve ->(o, a, c) { ... }
  end
end
```

You can also __opt out of all scalars__ by providing `monitor_scalars: false` at schema-level. For example:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  # Don't monitor any Strings, Ints, Floats, IDs, Booleans, or custom scalars
  monitoring(:skylight, monitor_scalars: false)
end
```

If you opt out of scalars, you can specify `monitoring(true)` to keep an eye on _specific_ fields or scalar types:

```ruby
CommentType = GraphQL::ObjectType.define do
  # ...
  # Opt in to monitoring this field:
  field :rating, types.Float, monitoring: true
end

DateTimeType = GraphQL::Scalar.define do
  # ...
  # Always monitor fields that return this type:
  monitoring true
end
```

This gives you fine-tuned control over how your schema is instrumented.

## AppSignal

Add [AppSignal](https://appsignal.com/) instrumentation with `monitoring(:appsignal)`, for example:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  monitoring(:appsignal)
end
```

<div class="monitoring-img-group">
  {{ "/pro/appsignal_1.png" | link_to_img:"appsignal monitoring" }}
  {{ "/pro/appsignal_2.png" | link_to_img:"appsignal monitoring" }}
</div>

## Datadog

Add [Datadog APM](https://www.datadoghq.com/apm/) instrumentation with `monitoring(:datadog)`, for example:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  monitoring(:datadog)
end
```

This requires the [`ddtrace` gem](https://github.com/DataDog/dd-trace-rb), make sure to include it in your gemfile:

```ruby
gem "ddtrace"
```

<div class="monitoring-img-group">
  {{ "/pro/datadog_1.png" | link_to_img:"datadog graphql monitoring" }}
  {{ "/pro/datadog_2.png" | link_to_img:"datadog graphql monitoring" }}
</div>

## New Relic

Add [New Relic](https://newrelic.com/) instrumentation with `monitoring(:new_relic)`, for example:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  monitoring(:new_relic)
end
```

<div class="monitoring-img-group">
  {{ "/pro/newrelic_1.png" | link_to_img:"new relic monitoring" }}
  {{ "/pro/newrelic_2.png" | link_to_img:"new relic monitoring" }}
</div>

## Scout

Add [Scout](https://scoutapp.com) instrumentation with `monitoring(:scout)`, for example:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  monitoring(:scout)
end
```

<div class="monitoring-img-group">
  {{ "/pro/scout_1.png" | link_to_img:"scout monitoring" }}
  {{ "/pro/scout_2.png" | link_to_img:"scout monitoring" }}
</div>

## Skylight

Add [Skylight](http://skylight.io) instrumentation with `monitoring(:skylight)`, for example:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  monitoring(:skylight)
end
```

<div class="monitoring-img-group">
  {{ "/pro/skylight_2.png" | link_to_img:"skylight monitoring" }}
  {{ "/pro/skylight_1.png" | link_to_img:"skylight monitoring" }}
</div>
