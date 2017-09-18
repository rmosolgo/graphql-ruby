---
title: Backtrace Annotations
layout: guide
search: true
section: Queries
desc: Improve debugging with additional backtrace context
index: 12
experimental: true
---

You can add information to Ruby error backtraces with `GraphQL::Backtrace`. To enable this feature, use `.enable`, for example:

```ruby
# Start backtrace annotations
GraphQL::Backtrace.enable
```

Now, backtraces will contain GraphQL-related context, for example:

<pre>
GraphQL::EnumType::UnresolvedValueError: Can't resolve enum Manner for TRILL
    /graphql-ruby/lib/graphql/enum_type.rb:124:in `coerce_result' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:185:in `resolve_value' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:155:in `continue_resolve_field' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:129:in `resolve_field' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:71:in `block (2 levels) in resolve_selection' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/tracing.rb:40:in `block in trace' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/tracing.rb:68:in `block (2 levels) in call_tracer' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/tracing.rb:66:in `call_tracer' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/tracing.rb:68:in `block in call_tracer' <strong>GraphQL: Phoneme.manner</strong>
    /graphql-ruby/lib/graphql/backtrace.rb:51:in `trace' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/tracing.rb:68:in `call_tracer' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/tracing.rb:40:in `trace' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:70:in `block in resolve_selection' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:63:in `each' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:63:in `resolve_selection' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:218:in `resolve_value' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:234:in `resolve_value' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:155:in `continue_resolve_field' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:129:in `resolve_field' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/execution/execute.rb:71:in `block (2 levels) in resolve_selection' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/tracing.rb:40:in `block in trace' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/tracing.rb:68:in `block (2 levels) in call_tracer' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/tracing.rb:66:in `call_tracer' <strong>GraphQL: Query.unit(name: "Uvular Trill")</strong>
    /graphql-ruby/lib/graphql/tracing.rb:68:in `block in call_tracer' <strong>GraphQL: query &lt;Anonymous&gt;</strong>
</pre>

Later, you can disable this with `.disable`:

```ruby
# End backtrace annotations
GraphQL::Backtrace.disable
```
