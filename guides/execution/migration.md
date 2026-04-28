---
layout: guide
doc_stub: false
search: true
section: Execution
title: Migrating to Execution::Next
desc: Guidelines for migrating to the new execution engine
index: 2
---

This guide includes tips for migrating your schema configuration and production traffic to the new engine.

## Migration Philosophy

`Execution::Next` is designed to run alongside the previous engine so that the same schema can run queries _both_ ways. This supports an incremental migration and live toggling in production.

First, update your schema to include the necessary {% internal_link "field configurations", "/execution/next#field-configurations" %}. If you implement new class methods in your Object type classes, you can also migrate instance methods to call "up" to those class methods, preserving a single source of truth:

```ruby
field :unpublished_posts, [Types::Post], resolve_each: true

# Support batching:
def self.unpublished_posts(object, context)
  object.posts.where(published: false).order("created_at DESC")
end

# Support legacy in a DRY way by calling the class method:
def unpublished_posts
  self.class.unpublished_posts(object, context)
end
```

Test your new configurations in CI by running a new build which calls `execution_next` instead of `execution`, for example:

```ruby
# test_helpers.rb
def run_graphql(...)
  if ENV["GRAPHQL_EXECUTION_NEXT"]
    MyAppSchema.execute_next(...)
  else
    MyAppSchema.execute(...)
  end
end
```

Adopting a feature flag system (described below) can also make this easier.

When all tests pass on `.execute_next`, you're ready to try it out in production.

## Migration and Clean-Up Script

`graphql_migrate_execution` is a command-line development tool that can automate many common GraphQL-Ruby field resolver patterns. Check out its docs and try out: https://rmosolgo.github.io/graphql_migrate_execution/

## Production Considerations

There are two categories of problems when migrating:

- Some schema misconfigurations may only be detected at runtime.
- The engine may have bugs. (It's brand-new code trying to emulate 10 years of incremental development!)

When migrating, these possibilities should be considered from three different angles. Using the new engine may...

- ...raise errors in new ways.
- ...return a different result than the old engine.
- ...perform worse than the old engine, especially because of different database access patterns.

To mitigate these possibilities, use dynamic release tools in production like feature flags and experiments.

### Feature Flags

You should use a feature flagging system so that you can shift traffic between old and new runtime engines without redeploying. A good feature-flagging system supports percentage-based flags, so that you can send 1% of traffic to new code while the other 99% uses existing code. After it runs without issues, you can increase the percentage. Or, if you discover issues in production (errors or performance), you can turn it back to 0% while you troubleshoot the problem.

For example:

```ruby
# app/controllers/graphql_controller.rb
exec_method = use_graphql_next? ? :execute_next : :execute
result = MyAppSchema.public_send(exec_method, query_string, context: { ... }, variables: { ... })
render json: result
```

[Flipper](https://github.com/flippercloud/flipper) is a great gem for feature flags. You could also roll your own or pick a third-party service.

__Before__ using `.execute_next` to produce results for production traffic, you might want to run an experiment as described below.

### Experiments

While the two runtime engines _should_ return identical responses, it's possible that `.execute_next` will return a different result than `.execute` due to gem bugs or schema misconfigurations. You can check for this using an "experiment" system in your application which runs _both_ execution engines and compares the result (for __queries only__!).

You'll want to use feature flagging to run the experiment on a subset of traffic, since it comes with performance overhead.

Here's some example code for a setup like this:

```ruby
# app/controllers/graphql_controller.rb
result = MySchema.execute(...)

# Use a dynamic flag, eg Flipper. This should always be true in development and test.
if use_graphql_next_experiment?
  if !query_string.include?("mutation") && !query_string.include?("subscription") # easy way of checking for queries, could possibly have false negatives
    batched_result = MySchema.execute_next(...)
    if batched_result.to_h != result.to_h
      # Log this mismatch somehow here, avoiding potential PII/passwords:
      BugTracker.report <<~TXT
        A GraphQL query returned a non-identical response. Sanitized query string:

        #{result.query.sanitized_query_string}

        User: #{current_user.id}
        # Other context info here...
      TXT
    end
  end
end
```

See [Scientist](https://github.com/github/scientist) for a full-blown production experimentation system.

## Combining feature flags and experiments

A fully-managed rollout would include two flags:

- `use_graphql_next_experiment?`: when true, build an `.execute_next` response and compare it to the `.execute` response. But _always_ return the `.execute` response.
- `use_graphql_next?`: when true, use `.execute_next` and don't call `.execute` at all

This gives you full control over how production traffic is executed without needing to redeploy. You can always turn them down to 0% to get the current behavior.

Here's some example code:

```ruby
if use_graphql_next? # again, use a dynamic feature flag
  result = MySchema.execute_next(...)
else
  result = MySchema.execute(...)
  if use_graphql_next_experiment?
    # Continue running the comparison experiment
  end
end

render json: result.to_h
```

## Compatibility Notes

Performance improvements in batching execution come at the cost of removing support for many "nice-to-have" features in GraphQL-Ruby by default. Those features are addressed here.

### Implicit Field Resolution

The _default_, _implicit_ field resolution behavior has changed. Previously, when a field didn't have a specified method or hash key, GraphQL-Ruby would try a combination of `object.public_send(...)` and `object[...]` to resolve it. In `Execution::Next`, GraphQL-Ruby tries `object.public_send(field_sym)` unless another configuration is provided. This removes a lot of overhead from field execution.

Consider a field like this:

```ruby
field :title, String
```

Previously, GraphQL-Ruby would check `type_object.respond_to?(:title)`, `object.respond_to?(:title)`, `object.is_a?(Hash)`. `object.key?(:title)` and `object.key?("title")`.

Now, GraphQL-Ruby simply calls `object.title` and allows the `NoMethodError` to bubble up if one is raised.

### Query Analyzers, including complexity 🟡

Support is identical; this runs before execution using the exact same code.

TODO: accessing loaded arguments inside analyzers may turn out to be slightly different; it still calls legacy code.

### Authorization, Scoping

Full compatibility. `def (self.)authorized?` and `def self.scope_items` will be called as needed during execution.

### Visibility, including Changesets

Visibility works exactly as before; both runtime modules call the same methods to get type information from the schema.

### Dataloader

Dataloader runs with new execution, but when migrating from instance methods to batch-level class methods, you may need to use {{ "Schema::Member::HasDataloader#dataload_all" | api_doc }} instead of `.dataload`.

### Tracing

Fully supported, but some legacy hooks are _not_ called. Implement the new hooks instead (existing runtime already calls these new hooks). Not called are:

- `execute_field`, `execute_field_lazy`: use `begin_execute_field`, `end_execute_field` instead. (These may be called multiple times when Dataloader pauses or a GraphQL-Batch promise is returned)
- `execute_query`, `execute_query_lazy`: use `execute_multiplex` for a top-level hook instead. (Single queries are always executed in a multiplex of size = 1.)
- `resolve_type`, `authorized`: use `{begin,end}_resolve_type` and `{begin,end}_authorized` instead. (May be called multiple times for Dataloader etc.)

### Lazy resolution (GraphQL-Batch)

Lazy resolution runs in the new execution (GraphQL-Batch is supported). When migrating to class methods, you may need to update your library method calls to work on a set of inputs rather than a single input.

### `current_path` ❌

This is not supported because the new runtime doesn't actually produce `current_path`.

It is theoretically possible to support this but it will be a ton of work. If you use this for core runtime functions, please share your use case in a GitHub issue and we can investigate future options.

### Scoped context ❌

This is currently implemented with `current_path`. Another implementation is probably possible but not implemented yet. Please open an issue to discuss.

### `@defer` 🟡

`@defer` is supported with an implementation difference that _probably_ doesn't affect your application: previously, `@defer` worked by pausing and resuming the _same `GraphQL::Query` instance_. However, with `Execution::Next`, `@defer` takes a different approach. Instead, when a `GraphQL::Query` encounters `@defer`, it notes the location in the document and stops executing that branch. Later, when you request the deferred result, that branch of the query is resumed using a new instance of `GraphQL::Query::Partial`.

This might matter if you're modifying `context` at runtime because those new instances _also_ have fresh `Query::Context` instances. The original query context _will_ get copied into the `@defer` branches using `Query::Context.new(**original_query.context.to_h)`, so any custom values will be available. But if you _assign new keys_ after the context is copied, those keys won't appear when running later `@defer`ed branches.

To handle this, you can refactor how you accumulate data during execution. Instead of `||=`'ing into `context[...]` during execution, assign a new accumulator object _before_ starting the query, then call methods on that object to make any necessary state changes. That new object _will_ be copied into `@defer` partials, and since the object is shared between the different branches, any necessary state changes will still be "seen" everywhere.

If this gives you trouble, please feel free to email me or open an issue on GitHub to discuss a migration strategy.

##### GraphQL-Batch support

When using `Execution::Next`, no custom code is required to support `graphql-batch` -- support is built-in.

### `@stream`

`@stream` is supported.

See the not above about how `@defer` no longer _resumes_ the original, top-level query. The same thing applies to `@stream`.

`GraphQL::Pro::Stream` now lazily streams Enumerators. If you were using the (undocumented) `GraphQL::Pro::FutureStream`, you can switch to `GraphQL::Pro::Stream` _after_ migrating to `Execution::Next`. (Once all your traffic uses the new execution module, you'll get the same runtime behavior from `GraphQL::Pro::Stream`.)

### ObjectCache

Supported completely.

### Custom Directives ❌

There is some implementation in the code right now but it's not stable. Please open an issue to discuss.

### `as:`

`as:` is applied: arguments are passed into Ruby methods by their `as:` names instead of their GraphQL names.

### `loads:` 🟡

`loads:` is handled as previously, __except__ that custom `def load_...` methods are _not_ called.

### `prepare:`

These methods/procs are called.

### `validates:` 🟡

Built-in validators are supported. Custom validators will always receive `nil` as the `object`. (`object` is no longer available; this API will probably change before this is fully released.)

### Field Extensions 🟡

Field extension methods are called with new arguments:

- `objects:` instead of `object:`, with an Array
- `values:` instead of `value:`, with an Array

You can support both types of calls in your methods by changing the signature to `object: nil, objects: nil` (and `value: nil, values: nil`), then checking which argument was passed.

### Resolver classes (including Mutations and Subscriptions) 🟡

Resolver classes are called, but with slightly different semantics:

- `#ready?` is still called, but after arguments are loaded. It's now a useless method and will probably be deprecated.
- `def load_...` methods are not called; instead, arguments are passed to the top-level `Schema.object_from_id` hook.

### Field `extras:`, including `lookahead`

`:ast_node` and `:lookahead` are already implemented. Others are possible -- please raise an issue if you need one. `extras: [:current_path]` is not possible.

### `raw_value` 🟡

Supported, but the `raw_value` call must be made on `context`, for example:

```ruby
field :values, SomeObjectType, resolve_static: true

def self.values(context)
  context.raw_value(...)
end
```

### Errors and `rescue_from`

Supported.

### Connection fields

Connection arguments are automatically handled and connection wrapper objects are automatically applied to arrays and relations.

### Custom Introspection

This _works_ but if you want custom authorization or any lazy values, see notes about that compatibility.

### Multiplex

To use the new engine to run a multiplex, use `MyAppSchema.multiplex_next(...)` with the same arguments.
