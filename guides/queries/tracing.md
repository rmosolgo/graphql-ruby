---
title: Tracing
layout: guide
doc_stub: false
search: true
section: Queries
desc: Observation hooks for execution
index: 11
---

{{ "GraphQL::Tracing::Trace" | api_doc }} provides hooks to observe and modify events during runtime. Tracing hooks are methods, defined in modules and mixed in with {{ "Schema.trace_with" | api_doc }}.

```ruby
module CustomTrace
  def parse(query_string:)
    # measure, log, etc
    yield
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

## ActiveSupport::Notifications

You can emit events to `ActiveSupport::Notifications` with an experimental tracer, `ActiveSupportNotificationsTracing`.

To enable it, install the tracer:

```ruby
# Send execution events to ActiveSupport::Notifications
class MySchema < GraphQL::Schema
  tracer(GraphQL::Tracing::ActiveSupportNotificationsTracing)
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
  use(GraphQL::Tracing::AppOpticsTracing)
end
```
<div class="monitoring-img-group">
  {{ "/queries/appoptics_example.png" | link_to_img:"appoptics monitoring" }}
</div>

## Appsignal

To add [AppSignal](https://appsignal.com/) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  use(GraphQL::Tracing::AppsignalTracing)
end
```

<div class="monitoring-img-group">
  {{ "/queries/appsignal_example.png" | link_to_img:"appsignal monitoring" }}
</div>

## New Relic

To add [New Relic](https://newrelic.com/) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  use(GraphQL::Tracing::NewRelicTracing)
  # Optional, use the operation name to set the new relic transaction name:
  # use(GraphQL::Tracing::NewRelicTracing, set_transaction_name: true)
end
```


<div class="monitoring-img-group">
  {{ "/queries/new_relic_example.png" | link_to_img:"new relic monitoring" }}
</div>

## Scout

To add [Scout APM](https://scoutapp.com/) instrumentation:

```ruby
class MySchema < GraphQL::Schema
  use(GraphQL::Tracing::ScoutTracing)
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
  use(GraphQL::Tracing::DataDogTracing, options)
end
```

You may provide `options` as a `Hash` with the following values:

| Key | Description | Default |
| --- | ----------- | ------- |
| `service` | Service name used for `graphql` instrumentation | `'ruby-graphql'` |
| `tracer` | `Datadog::Tracer` used to perform instrumentation. Usually you don't need to set this. | `Datadog.tracer` |

For more details about Datadog's tracing API, check out the [Ruby documentation](https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md) or the [APM documentation](https://docs.datadoghq.com/tracing/) for more product information.

## Prometheus

To add [Prometheus](https://prometheus.io) instrumentation:

```ruby
require 'prometheus_exporter/client'

class MySchema < GraphQL::Schema
  use(GraphQL::Tracing::PrometheusTracing)
end
```

The PrometheusExporter server must be run with a custom type collector that extends
`GraphQL::Tracing::PrometheusTracing::GraphQLCollector`:

```ruby
# lib/graphql_collector.rb
if defined?(PrometheusExporter::Server)
  require 'graphql/tracing'

  class GraphQLCollector < GraphQL::Tracing::PrometheusTracing::GraphQLCollector
  end
end
```

```sh
bundle exec prometheus_exporter -a lib/graphql_collector.rb
```

## Statsd

You can add Statsd instrumentation by initializing a statsd client and passing it to {{ "GraphQL::Tracing::StatsdTracing" | api_doc }}:

```ruby
$statsd = Statsd.new 'localhost', 9125
# ...

class MySchema < GraphQL::Schema
  use GraphQL::Tracing::StatsdTracing, statsd: $statsd
end
```

Any Statsd client that implements `.time(name) { ... }` will work.
