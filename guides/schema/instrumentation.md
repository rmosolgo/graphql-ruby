---
layout: guide
title: Instrumentation
section: Schema
desc: Programmatically modify resolve functions in your schema at build-time.
---

Instrumentation provides hooks for inserting custom code around field resolution and query execution.

## Field Instrumentation

## Query Instrumentation

Query instrumentation can be attached during schema definition:

```ruby
MySchema = GraphQL::Schema.define do
  instrument(:query, QueryTimerInstrumentation)
end
```

The instrumenter must implement `#before_query(query)` and `#after_query(query)`. The return values of these methods are not used. They receive the {{ "GraphQL::Query" | api_doc }} instance.

```ruby
module MyQueryInstrumentation
  module_function

  # Log the time of the query
  def before_query(query)
    Rails.logger.info("Query begin: #{Time.now.to_i}")
  end

  def after_query(query)
    Rails.logger.info("Query end: #{Time.now.to_i}")
  end
end
```
