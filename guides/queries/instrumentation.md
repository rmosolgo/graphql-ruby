---
title: Instrumentation
layout: guide
doc_stub: false
search: true
section: Queries
desc: Wrap query execution with custom logic
---

You can call hooks _before_ and _after_ each query. Query instrumentation can be attached during schema definition:

```ruby
class MySchema < GraphQL::Schema
  instrument(:query, QueryTimerInstrumentation)
end
```

The instrumenter must implement `#before_query(query)` and `#after_query(query)`. The return values of these methods are not used. They receive the {{ "GraphQL::Query" | api_doc }} instance.

```ruby
module QueryTimerInstrumentation
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
