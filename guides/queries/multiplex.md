---
title: Multiplex
layout: guide
doc_stub: false
search: true
section: Queries
desc: Run multiple queries concurrently
index: 10
---

Some clients may send _several_ queries to the server at once (for example, [Apollo Client's query batching](http://dev.apollodata.com/core/network.html#query-batching)). You can execute them concurrently with {{ "Schema#multiplex" | api_doc }}.

Multiplex runs have their own context, analyzers and instrumentation.

## Concurrent Execution

To run queries concurrently, build an array of query options, using `query:` for the query string. For example:

```ruby
# Prepare the context for each query:
context = {
  current_user: current_user,
}

# Prepare the query options:
queries = [
  {
   query: "query Query1 { someField }",
   variables: {},
   operation_name: 'Query1',
   context: context,
 },
 {
   query: "query Query2 ($num: Int){ plusOne(num: $num) }",
   variables: { num: 3 },
   operation_name: 'Query2',
   context: context,
 }
]
```

Then, pass them to `Schema#multiplex`:

```ruby
results = MySchema.multiplex(queries)
```

`results` will contain the result for each query in `queries`.

## Apollo Query Batching

Apollo sends the batch variables in a `_json` param, you also need to ensure that your schema can handle both batched and non-batched queries, below is an example of the default GraphqlController rewritten to handle Apollo batches:

```ruby
def execute
  context = {}

  # Apollo sends the params in a _json variable when batching is enabled
  # see the Apollo Documentation about query batching: http://dev.apollodata.com/core/network.html#query-batching
  result = if params[:_json]
    queries = params[:_json].map do |param|
      {
        query: param[:query],
        operation_name: param[:operationName],
        variables: ensure_hash(param[:variables]),
        context: context
      }
    end
    MySchema.multiplex(queries)
  else
    MySchema.execute(
      params[:query],
      operation_name: params[:operationName],
      variables: ensure_hash(params[:variables]),
      context: context
    )
  end

  render json: result
end
```

## Validation and Error Handling

Each query is validated and {% internal_link "analyzed","/queries/analysis" %} independently. The `results` array may include a mix of successful results and failed results

## Multiplex-Level Context

You can add values to {{ "Execution::Multiplex#context" | api_doc }} by providing a `context:` hash:

```ruby
MySchema.multiplex(queries, context: { current_user: current_user })
```

This will be available to instrumentation as `multiplex.context[:current_user]` (see below).

## Multiplex-Level Analysis

You can analyze _all_ queries in a multiplex by adding a multiplex analyzer. For example:

```ruby
class MySchema < GraphQL::Schema do
  # ...
  multiplex_analyzer(MyAnalyzer)
end
```

The API is the same as {% internal_link "query analyzers","/queries/analysis" %}, with some considerations:

- `initial_value` is called at the start of the _multiplex_ (not query)
- `final` is called at the end of the _multiplex_ (not query)
- `call(...)` is called for each node in _each_ query, so it will visit every node in the multiplex in sequence.

Multiplex analyzers may return {{ "AnalysisError" | api_doc }} to halt execution of the whole multiplex.

## Multiplex Instrumentation

You can add hooks for each multiplex run with multiplex instrumentation.

An instrumenter must implement `.before_multiplex(multiplex)` and `.after_multiplex(multiplex)`. Then, it can be mounted with `instrument(:multiplex, MyMultiplexAnalyzer)`. See {{ "Execution::Multiplex" | api_doc }} for available methods.

For example:

```ruby
# Count how many queries are in the multiplex run:
module MultiplexCounter
  def self.before_multiplex(multiplex)
    Rails.logger.info("Multiplex size: #{multiplex.queries.length}")
  end

  def self.after_multiplex(multiplex)
  end
end

# ...

class MySchema < GraphQL::Schema
  # ...
  instrument(:multiplex, MultiplexCounter)
end
```

Now, `MultiplexCounter.before_multiplex` will be called before each multiplex and `.after_multiplex` will run after each multiplex.
