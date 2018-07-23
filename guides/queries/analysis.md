---
layout: guide
doc_stub: false
search: true
section: Queries
title: Ahead-of-Time Analysis
desc: Check incoming query strings and reject them if they don't pass your checks
index: 1
---

You can provide logic for validating incoming queries and rejecting them if they don't pass. _Query analyzers_ inspect the query and may return {{ "GraphQL::AnalysisError" | api_doc }} to halt execution.

GraphQL's `max_depth` and `max_complexity` are implemented with query analyzers, you can see those for reference:

- {{ "GraphQL::Analysis::QueryDepth" | api_doc }}
- {{ "GraphQL::Analysis::QueryComplexity" | api_doc }}

## Analyzer API

A query analyzer visits each field in the query _before_ the query is executed. It can accumulate data during the visits, then return a value. If the returned value is a {{ "GraphQL::AnalysisError" | api_doc }} (or an array of those errors), the query won't be executed and the error will be returned to the user. You can use this feature to assert that queries are permitted _before_ running them!

Query analyzers reuse concepts from `Array#reduce`, so let's briefly revisit how that method works:

```ruby
items = [1, 2, 3, 4, 5]
initial_value = 0
reduce_result = items.reduce(initial_value) { |memo, item| memo + item }
final_value = "Sum: #{reduce_result}"
puts final_value
# Sum: 15
```

- `reduce` accepts an _initial value_ and a _callback_ (as a block)
- The callback receives the reduce _state_ (`memo`) and each item of the array (`item`)
- For each call to the callback, the return value is the new state and it will be provided to the _next_ call to the callback
- When each item has been visited, the last value of the callback state (the last `memo` value) is returned
- Then, you can use the reduced value in your application

A query analyzer has the same basic parts. Here's the scaffold for an analyzer:

```ruby
class MyQueryAnalyzer
  # Called before initializing the analyzer.
  # Returns true to run this analyzer, or false to skip it.
  def analyze?(query)
  end

  # Called before the visit.
  # Returns the initial value for `memo`
  def initial_value(query)
  end

  # This is like the `reduce` callback.
  # The return value is passed to the next call as `memo`
  def call(memo, visit_type, irep_node)
  end

  # Called when we're done the whole visit.
  # The return value may be a GraphQL::AnalysisError (or an array of them).
  # Or, you can use this hook to write to a log, etc
  def final_value(memo)
  end
end
```

- `#analyze?` is called before initializing any analyzer if it is defined. When `#analyze?` returns false, the analyzer won't be ran.
- `#initial_value` is a chance to initialize the state for your analysis. For example, you can return a hash with keys for the query, schema, and any other values you want to store.
- `#call` is called for each node in the query. `memo` is the analyzer state. `visit_type` is either `:enter` or `:leave`. `irep_node` is the {{ "GraphQL::InternalRepresentation::Node" | api_doc }} for the current field in the query. (It is like `item` in the `Array#reduce` callback.)
- `#final_value` is called _after_ the visit. It provides a chance to write to your log or return a {{ "GraphQL::AnalysisError" | api_doc }} to halt query execution.

Query analyzers are added to the schema with `query_analyzer`, for example:

```ruby
class MySchema < GraphQL::Schema
  query_analyzer MyQueryAnalyzer.new
end
```
