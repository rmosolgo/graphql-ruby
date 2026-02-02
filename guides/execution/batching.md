---
layout: guide
doc_stub: false
search: true
section: Execution
title: New Execution Module
desc: Background on GraphQL-Ruby's new execution approach
index: 1
---

GraphQL-Ruby has a new execution module under development, {{ "GraphQL::Execution::Batching" | api_doc }}. It's not yet recommended for production use, but you can try it in development as described below.

It's much faster and less memory-consuming than the existing execution module, but it doesn't support every feature that the existing module does.

This feature is in heavy development, so if you give it a try and run into any problems, please open an issue on GitHub!

## Background

Breadth-first GraphQL execution (or, "execution batching") is an algorithmic paradigm developed by Shopify to address problems of scale when resolving large lists and nested sets. Rather than paying field-level overhead costs (resolver calls, instrumentation, lazy promises, etc) for every field _of every resolved object_, the pattern instead incurs these costs only once per field selection and runs the corresponding breadth of objects with no additional overhead.

The original proof-of-concept of Shopify's core algorithm and white paper notes can be found in [graphql-breadth-exec](https://github.com/gmac/graphql-breadth-exec). That prototype matured into Shopify's proprietary _GraphQL Cardinal_ execution engine that now runs much of their core traffic.

GraphQL-Ruby brings these breadth-first design principles to the open-source community with several novel techniques for implementing GraphQL:

- Fields are resolved breadth-first using implicitly batched resolvers (no DataLoader). These run longer and hotter on application logic with no execution overhead.
- Batched resolvers may bind entire load sets to a single lazy promise to dramatically reduce promise bloat. 
- Error handling is optimized into a second pass that only runs when errors actually occur.
- Stack profiling becomes much more organized with a linear flow and aggregate field spans, rather than fields getting split up across subtree repetitions.
- The engine is driven by enqueuing rather than recursion, which shrinks stack traces and reduces memory usage.

Breadth-first patterns can produce dramatic results in responses with a high degree of repetition: it's not uncommon to see breadth batching run __15x__ faster and use __75% less__ memory than classic GraphQL Ruby execution. However – gains are relative. A flat tree with no lists will see little difference. A list of 2 resolving one field each will see a small gain, while a list of 100 resolving ten fields each will likely see dramatic results.

The downside is that many of GraphQL-Ruby's "bonus features" -- beyond the behavior described in the GraphQL Specification -- are either _impossible_ to implement in this paradigm or add non-trivial latency when added back in. So, the task ahead is to "lift the ceiling" of performance in GraphQL-Ruby while retaining as much compatibility as possible and supporting a gradual transition to this new runtime engine.

## Enabling Batching Execution

Batching execution is enabled with two steps:

- Require the code (it's loaded by default): `require "graphql/execution/batching"`
- Call `MySchema.execute_batching(...)` instead of `MySchema.execute(...)`. It takes the same arguments.

See compatibility notes for getting queries to run properly.

## "Native Batching" configurations

The new runtime engine supports several resolver configurations out of the box, without any compatibility shims:

- __Method calls__: fields that call `object.#{field_name}`. This is the default, and the method name can be overridden with `method: ...`:

    ```ruby
    field :title, String # calls object.title
    field :title, String, method: :get_title_somehow # calls object.get_title_somehow
    ```
- __Hash keys__: fields that call `object[hash_key]`, configured with `hash_key: ...`.


    ```ruby
    field :title, String, hash_key: :title # calls object[:title]
    field :title, String, hash_key: "title" # calls object["title"]
    ```

    (Note: batching execution doesn't "fall back" to hash key lookups, and it doesn't try strings when Symbols are given. The existing runtime engine does that...)

- __Batch resolvers__: fields that use a _class method_ to map parent objects to field results, configured with `resolve_batch:`:

    ```ruby
    field :title, String, resolve_batch: :titles do
      argument :language, Types::Language, required: false, default_value: "EN"
    end

    def self.titles(objects, context, language:)
      # This is equivalent to plain `field :title, ...`, but for example:
      objects.map { |obj| obj.title(language:) }
    end
    ```

    This is especially useful when batching Dataloader calls:

    ```ruby
    class Types::Comment < BaseObject
      field :post, Types::Post, resolve_batch: :posts

      # Use `.load_all(ids)` to fetch all in a single round-trip
      def self.posts(objects, context)
        # TODO: add a shorthand for this in GraphQL-Ruby
        context.dataloader
          .with(GraphQL::Dataloader::ActiveRecordSource)
          .load_all(objects.map(&:post_id))
      end
    end
    ```

- __Each resolvers__: fields that use a _class method_ to produce a result for each parent object, configured with `resolve_each:`. This is similar to `resolve_batch:`, except you never receive the whole list of `objects`:

    ```ruby
    field :title, String, resolve_each: :title do
      argument :language, Types::Language, required: false, default_value: "EN"
    end

    def self.title(object, context, language:)
      object.title(language:)
    end
    ```

    (Under the hood, GraphQL-Ruby calls `objects.map { ... }`, calling this class method.)

- __Static resolvers__: fields that use a _class method_ to produce a single result shared by all objects, configured with `resolve_static:`. The method does _not_ receive any `object`, only `context`:

    ```ruby
    field :posts_count, Integer, resolve_static: :count_all_posts do
      argument :include_unpublished, Boolean, required: false, default_value: false
    end

    def self.count_all_posts(context, include_unpublished:)
      posts = Post.all
      if !include_unpublished
        posts = posts.published
      end
      posts.count
    end
    ```

    (Under the hood, GraphQL-Ruby calls `Array.new(objects.size, static_result)`)


### `true` shorthand

There is also a `true` shorthand: when one of the `resolve_...:` configurations is passed as `true` (ie, `resolve_batch: true`, `resolve_each: true`, or `resolve_static: true`), then the Symbol field name is used as the class method. For example:

```ruby
field :posts_count, Integer, resolve_static: true

def self.posts_count(context)
  Post.all.count
end
```

## Migration Path

Migrating to batching execution is not terribly easy, but it's worth it for the performance gain.

One schema can run _both_ legacy execution and batching execution. This enable a step-wise adoption path:

1. Update your schema so that it it supports _both_ execution modes.
    - Add a CI run that uses batching execution for all GraphQL; run it alongside your normal CI
    - Add "native batching" configurations as described above until CI passes
    - Implementation methods _can_ call one another, for example:

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

1. Benchmark

   This is a good time to use your favorite benchmarking tools to see the payoff for your work. You could even use GraphQL-Ruby's own {{ "Tracing::DetailedTrace" | api_doc }}, where GraphQL-Ruby overhead is essentially the blank space between spans.

1. Compare the output of batched vs. legacy execution

    The two runtimes _should_ create identical results, and you can test this in CI, development, and production.

    ```ruby
    result = MySchema.execute(...)

    # Use a dynamic flag, eg Flipper. This should always be true in development and test.
    if should_run_batching_experiment?
      if !query_string.include?("mutation") && !query_string.include?("subscription") # easy way of checking for queries, could possibly have false negatives
        batched_result = MySchema.execute_batching(...)
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

    By using a dynamic feature flag, you can enable this check for a small portion of production traffic (including 0% if you find something is going wrong). Let it run for a while.

    Note that the experiment should run for __queries only__ -- you don't want to produce double side-effects for mutations and queries!

    - See [Flipper](https://github.com/flippercloud/flipper) for feature flags, or roll your own or pick a third-party service
    - See [Scientist](https://github.com/github/scientist) for a full-blown production experimentation system

1. After running the experiment, add a new flag to **return** the batching result instead of the legacy result:

    ```ruby
    if should_use_graphql_future? # again, use a dynamic feature flag
      result = MySchema.execute_batching(...)
    else
      result = MySchema.execute(...)
      if should_run_batching_experiment?
        # Optionally continue running the comparison experiment
      end
    end

    render json: result.to_h
    ```

    Turn up this flag in production until either:

    - It turns up new errors. In this case, turn the flag back to 0%, fix the error, and repeat.
    - You reach 100%. Let it run for some time this way, to make sure you don't run into errors.

    Optionally, you could also `rescue StandardError` and fall back to classic `.execute`.

1. After running batching execution for a while, remove the old code and always use `.execute_batching`.

    ```ruby
    result = MySchema.execute_batching(...)
    render json: result.to_h
    ```

    Also, remove old instance methods and unused configurations from your schema. (TODO: write a Rubocop rule that removes these.)

## Compatibility Notes

Performance improvements in batching execution come at the cost of removing support for many "nice-to-have" features in GraphQL-Ruby by default. Those features are addressed here.

### Query Analyzers, including complexity

### Authorization, Scoping

- Objects
- Fields
- Arguments
- Resolvers

### Visibility, including Changesets

### Dataloader

### Tracing

### Lazy resolution (GraphQL-Batch)

### `current_path`

### `@defer` and `@stream`

### Caching

### Argument `as:`

### Argument `loads:`

### Argument `prepare:`

### Argument `validates:`

### Field Extensions

### Resolver classes (including Mutations and Subscriptions)

### Field `extras:`, including `lookahead`

### `raw_value`

### Errors and `rescue_from`

- rescue_from handlers
- raising GraphQL::ExecutionError
- Schema class error handling hooks

### Connection fields

### Custom Introspection
