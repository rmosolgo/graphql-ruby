# Tracing

[GraphQL::Tracing::Trace](rdoc-ref:GraphQL::Tracing::Trace) provides hooks to observe and modify events during runtime. Tracing hooks are methods, defined in modules and mixed in with [Schema.trace_with](rdoc-ref:GraphQL::Schema.trace_with).

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

For a full list of methods and their arguments, see [GraphQL::Tracing::Trace](rdoc-ref:GraphQL::Tracing::Trace).

By default, GraphQL-Ruby makes a new trace instance when it runs a query. You can pass an existing instance as `context: { trace: ... }`. Also, `GraphQL.parse( ..., trace: ...)` accepts a trace instance.

## Detailed Traces

You can capture detailed traces of query execution with [Tracing::DetailedTrace](rdoc-ref:GraphQL::Tracing::DetailedTrace). They can be viewed in Google's [Perfetto Trace Viewer](https://ui.perfetto.dev). They include a per-Fiber breakdown with links between fields and Dataloader sources.

![GraphQL-Ruby Dataloader Perfetto Trace](/queries/perfetto_example.png)

Learn how to set it up in the [Tracing::DetailedTrace](rdoc-ref:GraphQL::Tracing::DetailedTrace) docs.

## External Monitoring Platforms

There integrations for GraphQL-Ruby with several other monitoring systems:

- `ActiveSupport::Notifications`: See [Tracing::ActiveSupportNotificationsTrace](rdoc-ref:GraphQL::Tracing::ActiveSupportNotificationsTrace).
- [AppOptics](https://appoptics.com/) instrumentation is automatic in `appoptics_apm` v4.11.0+.
- [AppSignal](https://appsignal.com/): See [Tracing::AppsignalTrace](rdoc-ref:GraphQL::Tracing::AppsignalTrace).
- [Datadog](https://www.datadoghq.com): See [Tracing::DataDogTrace](rdoc-ref:GraphQL::Tracing::DataDogTrace).
- [NewRelic](https://newrelic.com/): See [Tracing::NewRelicTrace](rdoc-ref:GraphQL::Tracing::NewRelicTrace).
- [Prometheus](https://prometheus.io): See [Tracing::PrometheusTrace](rdoc-ref:GraphQL::Tracing::PrometheusTrace).
- [Scout APM](https://www.scoutapm.com/): See [Tracing::ScoutTrace](rdoc-ref:GraphQL::Tracing::ScoutTrace).
- [Sentry](https://sentry.io): See [Tracing::SentryTrace](rdoc-ref:GraphQL::Tracing::SentryTrace).
- [Skylight](https://www.skylight.io):  either enable the [GraphQL probe](https://www.skylight.io/support/getting-more-from-skylight#graphql) or use [Tracing::ActiveSupportNotificationsTrace](rdoc-ref:GraphQL::Tracing::ActiveSupportNotificationsTrace).
- Statsd: See [Tracing::StatsdTrace](rdoc-ref:GraphQL::Tracing::StatsdTrace).
