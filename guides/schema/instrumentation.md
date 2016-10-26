---
title: Schema — Instrumentation
---

Instrumentation provides hooks for inserting custom code around field resolution and query execution.

## Field Instrumentation

Field instrumentation can be attached during schema definition:

```ruby
MySchema = GraphQL::Schema.define do
  instrument(:field, MyFieldInstrumentation.new)
end
```

The instrumenter is an object which responds to `#instrument(type, field)`. `#instrument` should return a `GraphQL::Field` instance which will be used during query execution. `#instrument` is called with each type-field pair for _all_ Object types and Interface types in your schema.

Here's an example field instrumenter:

```ruby
class MyFieldInstrumentation
  # If a field was flagged to be timed,
  # wrap its resolve proc with a timer.
  def instrument(type, field)
    if field.metadata[:timed]
      old_resolve_proc = field.resolve_proc
      new_resolve_proc = ->(obj, args, ctx) {
        Rails.logger.info("#{type.name}.#{field.name} START: #{Time.now.to_i}")
        old_resolve_proc.call(obj, args, ctx)
        Rails.logger.info("#{type.name}.#{field.name} END: #{Time.now.to_i}")
      }
    end
  end
end
```

It can be attached as shown above. This implementation will _modify_ the underlying `GraphQL::Field` instance... be warned!

## Query Instrumetation


Query instrumentation can be attached during schema definition:

```ruby
MySchema = GraphQL::Schema.define do
  instrument(:query, MyQueryInstrumentation.new)
end
```

The instrumenter must implement `#before_query(query)` and `#after_query(query)`. The return value of these methods are not used. They receive the `GraphQL::Query` instance.

```ruby
class MyQueryInstrumentation
  # Log the time of the query
  def before_query(query)
    Rails.logger.info("Query begin: #{Time.now.to_i}")
  end

  def after_query(query)
    Rails.logger.info("Query end: #{Time.now.to_i}")
  end
end
```
