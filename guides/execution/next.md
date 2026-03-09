---
layout: guide
doc_stub: false
search: true
experimental: true
section: Execution
title: New Execution Module
desc: Background on GraphQL-Ruby's new execution approach
index: 1
---

GraphQL-Ruby has a new execution engine under development, {{ "GraphQL::Execution::Next" | api_doc }}. It's not yet recommended for production use, but you can try it in development as described below.

It's much faster and less memory-consuming than the existing execution engine, but requires some care in migrating.

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

The downside is that many of GraphQL-Ruby's "bonus features" -- beyond the behavior described in the GraphQL Specification -- add non-trivial latency when used. So, the task ahead is to "lift the ceiling" of performance in GraphQL-Ruby while retaining as much compatibility as possible and supporting a gradual transition to this new runtime engine.

## Enabling Execution::Next

The new execution engine is enabled with two steps:

- Add the plugin to your schema with `use GraphQL::Execution::Next`
- Call `MySchema.execute_next(...)` instead of `MySchema.execute(...)`. It takes the same arguments.

See {% internal_link "compatibility notes", "/execution/migration#compatibility-notes" %} for updating your schema to run queries with the new engine.

## Field configurations

The new runtime engine supports several field resolution configurations out of the box.

### Method calls (default, `method:`)

Fields that call `object.#{field_name}`. This is the default, and the method name can be overridden with `method: ...`:

```ruby
field :title, String # calls object.title
field :title, String, method: :get_title_somehow # calls object.get_title_somehow
```

### Hash keys (`hash_key:`)

Fields that call `object[hash_key]`, configured with `hash_key: ...`.

```ruby
field :title, String, hash_key: :title # calls object[:title]
field :title, String, hash_key: "title" # calls object["title"]
```

(Note: new execution doesn't "fall back" to hash key lookups, and it doesn't try strings when Symbols are given. The existing runtime engine does that...)

### Per-object (`resolve_each:`)

These fields use a _class method_ to produce a result for each parent object, configured with `resolve_each:`.

```ruby
field :title, String, resolve_each: :title do
  argument :language, Types::Language, required: false, default_value: "EN"
end

def self.title(object, context, language:)
  # Assuming this makes no database lookups or other external service calls:
  object.localization.get(:title, language:)
end
```

Under the hood, GraphQL-Ruby calls `objects.map { ... }`, calling this class method.

‼️ __Don't use this__ if your logic calls external services or databases (including with Dataloader). If you do, your I/O will be sequential instead of batched. Use `resolve_batch:` or `resolve_static:` instead, see below.

### Global (`resolve_static:`)

Fields that use a _class method_ to produce a single result shared by all objects, configured with `resolve_static:`. The method does _not_ receive any `object`, only `context`:

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

Under the hood, GraphQL-Ruby calls `Array.new(objects.size, static_result)`.

### Batch resolvers (`resolve_batch:`)

This is a high-performance option for when you need to do I/O to generate results. By working with a batch of objects, you can greatly reduce the framework overhead in preparing a result.

These fields use a _class method_ to map parent objects to field results, configured with `resolve_batch:`:

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

### Legacy instance methods

`resolve_legacy_instance_method:`

There is _partial_ support for instance methods on Object type classes, for now. It will be deprecated and removed soon.

‼️ Don't use legacy instance methods with Dataloader. It will be sequential, not batched. ‼️

```ruby
field :title, String, resolve_legacy_instance_method: true do
  argument :language, Types::Language, required: false, default_value: "EN"
end

def title(language:)
  # Assuming this makes no database lookups or other external service calls:
  object.localization.get(:title, language:)
end
```

Under the hood, GraphQL-Ruby calls `objects.map { ... }`, calling this instance method.


### `true` shorthand

There is also a `true` shorthand: when one of the `resolve_...:` configurations is passed as `true` (ie, `resolve_batch: true`, `resolve_each: true`, `resolve_static: true`, or `resolve_legacy_instance_method: true`), then the Symbol field name is used as the class method. For example:

```ruby
field :posts_count, Integer, resolve_static: true

def self.posts_count(context)
  Post.all.count
end
```


## Migration

Read about migrating in the {% internal_link "Migration Doc", "/execution/migration" %}.
