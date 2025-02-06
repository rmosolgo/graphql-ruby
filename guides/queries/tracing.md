---
title: Tracing
layout: guide
doc_stub: false
search: true
section: Queries
desc: Observation hooks for execution
index: 11
redirect_from:
  - /queries/instrumentation
---

{{ "GraphQL::Tracing::Trace" | api_doc }} provides hooks to observe and modify events during runtime. Tracing hooks are methods, defined in modules and mixed in with {{ "Schema.trace_with" | api_doc }}.

```ruby
module CustomTrace
  def parse(query_string:)
    # measure, log, etc
    super
  end

  # ...
end
```

To include a trace module when running queries, add it to the schema with `trace_with`:

```ruby
# Run `MyCustomTrace` for all queries
class MySchema < GraphQL::Schema
  trace_with(MyCustomTrace)
end
```

For a full list of methods and their arguments, see {{ "GraphQL::Tracing::Trace" | api_doc }}.

By default, GraphQL-Ruby makes a new trace instance when it runs a query. You can pass an existing instance as `context: { trace: ... }`. Also, `GraphQL.parse( ..., trace: ...)` accepts a trace instance.

## Trace Modes

You can attach a trace module to run only in some circumstances by using `mode:`. For example, to add detailed tracing for only some requests:

```ruby
trace_with DetailedTrace, mode: :detailed_metrics
```

Then, to opt into that trace, use `context: { trace_mode: :detailed_metrics, ... }` when executing queries.

Any custom trace modes _also_ include the default `trace_with ...` modules (that is, those added _without_ any particular `mode: ...` configuration).

## Perfetto Traces

For detailed profiles of complex queries, try {{ "Tracing::PerfettoTrace" | api_doc }}. Its trace can be viewed in Google's [Perfetto Trace Viewer](https://ui.perfetto.dev). They include a per-Fiber breakdown with links between fields and Dataloader sources.

<div class="monitoring-img-group">
  {{ "/queries/perfetto_example.png" | link_to_img:"GraphQL-Ruby Dataloader Perfetto Trace" }}
</div>

## ActiveSupport::Notifications

You can emit events to `ActiveSupport::Notifications` with an experimental tracer, `ActiveSupportNotificationsTrace`.

To enable it, install the tracer:

```ruby
# Send execution events to ActiveSupport::Notifications
class MySchema < GraphQL::Schema
  trace_with(GraphQL::Tracing::ActiveSupportNotificationsTrace)
end
```

## Monitoring

Several monitoring platforms are supported out-of-the box by GraphQL-Ruby (see platforms below).

Leaf fields are _not_ monitored (to avoid high cardinality in the metrics service).

## AppOptics

[AppOptics](https://appoptics.com/) instrumentation will be automatic starting
with appoptics_apm-4.11.0.gem. For earlier gem versions please add appoptics_apm
tracing as follows:

```ruby
require 'appoptics_apm'

class MySchema < GraphQL::Schema
  trace_with GraphQL::Tracing::AppOpticsTrace
end
```
<div class="monitoring-img-group">
  {{ "/queries/appoptics_example.png" | link_to_img:"appoptics monitoring" }}
</div>

## Appsignal

To add [AppSignal](https://appsignal.com/) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  trace_with GraphQL::Tracing::AppsignalTrace
end
```

<div class="monitoring-img-group">
  {{ "/queries/appsignal_example.png" | link_to_img:"appsignal monitoring" }}
</div>

## New Relic

To add [New Relic](https://newrelic.com/) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  trace_with GraphQL::Tracing::NewRelicTrace
  # Optional, use the operation name to set the new relic transaction name:
  # trace_with GraphQL::Tracing::NewRelicTrace, set_transaction_name: true
end
```


<div class="monitoring-img-group">
  {{ "/queries/new_relic_example.png" | link_to_img:"new relic monitoring" }}
</div>

## Scout

To add [Scout APM](https://scoutapp.com/) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  trace_with GraphQL::Tracing::ScoutTrace
end
```

<div class="monitoring-img-group">
  {{ "/queries/scout_example.png" | link_to_img:"scout monitoring" }}
</div>

## Skylight

To add [Skylight](https://www.skylight.io) instrumentation, you may either enable the [GraphQL probe](https://www.skylight.io/support/getting-more-from-skylight#graphql) or use [ActiveSupportNotificationsTracing](/queries/tracing.html#activesupportnotifications).

```ruby
# config/application.rb
config.skylight.probes << "graphql"
```

<div class="monitoring-img-group">
  {{ "/queries/skylight_example.png" | link_to_img:"skylight monitoring" }}
</div>

GraphQL instrumentation for Skylight is available in versions >= 4.2.0.

## Datadog

To add [Datadog](https://www.datadoghq.com) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  trace_with GraphQL::Tracing::DataDogTrace
end
```

For more details about Datadog's tracing API, check out the [Ruby documentation](https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md) or the [APM documentation](https://docs.datadoghq.com/tracing/) for more product information.

## Prometheus

To add [Prometheus](https://prometheus.io) instrumentation:

```ruby
require 'prometheus_exporter/client'

class MySchema < GraphQL::Schema
  trace_with GraphQL::Tracing::PrometheusTrace
end
```

The PrometheusExporter server must be run with a custom type collector that extends
`GraphQL::Tracing::PrometheusTracing::GraphQLCollector`:

```ruby
# lib/graphql_collector.rb
if defined?(PrometheusExporter::Server)
  require 'graphql/tracing'

  class GraphQLCollector < GraphQL::Tracing::PrometheusTrace::GraphQLCollector
  end
end
```

```sh
bundle exec prometheus_exporter -a lib/graphql_collector.rb
```

## Sentry

To add [Sentry](https://sentry.io) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  trace_with GraphQL::Tracing::SentryTrace
end
```

<div class="monitoring-img-group">
  {{ "/queries/sentry_example.png" | link_to_img:"sentry monitoring" }}
</div>


## Statsd

You can add Statsd instrumentation by initializing a statsd client and passing it to {{ "GraphQL::Tracing::StatsdTrace" | api_doc }}:

```ruby
$statsd = Statsd.new 'localhost', 9125
# ...

class MySchema < GraphQL::Schema
  use GraphQL::Tracing::StatsdTrace, statsd: $statsd
end
```

Any Statsd client that implements `.time(name) { ... }` will work.
