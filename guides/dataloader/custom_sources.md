---
layout: guide
doc_stub: false
search: true
section: Dataloader
title: Custom sources
desc: Writing a custom Dataloader source for GraphQL-Ruby
index: 3
---

To write a custom dataloader source, you have to consider a few points:

- Batch keys: these inputs tell the dataloader how work can be batched
- Fetch parameters: these inputs are accumulated into batches, and dispatched all at once
- Executing the service call: How to take inputs and group them into an external call
- Handling the results: mapping the results of the external call back to the fetch parameters

Additionally, custom sources can perform their service calls in [background threads](#background-threads).

For this example, we'll imagine writing a Dataloader source for a non-ActiveRecord SQL backend.

## Batch Keys, Fetch Parameters

`GraphQL::Dataloader` assumes that external sources have two kinds of parameters:

- __Batch keys__ are parameters which _distinguish_ batches from one another; calls with different batch keys are resolved in different batches.
- __Fetch parameters__ are parameters which _merge_ into batches; calls with the same batch keys but different fetch parameters are merged in the same batch.

Looking at SQL:

- tables are _batch keys_: objects from different tables will be resolved in different batches.
- IDs are _fetch parameters_: objects with different IDs may be fetched in the same batch (given that they're on the same table).

With this in mind, our source's public API will look like this:

```ruby
# To request a user by ID:
SQLDatabase.load("users", user_id)
#                ^^^^^^^           <- Batch key (table name)
#                         ^^^^^^^  <- Fetch parameter (id)
```

With an API like that, the source could be used for general purpose ID lookups:

```ruby
SQLDatabase.load("products", product_id_1)   #  <
SQLDatabase.load("products", product_id_2)   #  < These two will be resolved in the batch

SQLDatabase.load("reviews", review_id)       #  < This will be resolved in a different batch
```

{{ "GraphQL::Dataloader::Source.load" | api_doc }} assumes that the final argument is a _fetch parameter_ and that all other arguments (if there are any) are batch keys. So, our Source class won't need to modify that method.

However, we'll want to capture the table name for each batch, and we'll use `#intialize` for that:

```ruby
class SQLDatabase < GraphQL::Dataloader::Source
  def initialize(table_name)
    # Next, we'll use `@table_name` to prepare a SQL query, see below
    @table_name
  end
end
```

Each time GraphQL-Ruby encounters a new batch key, it initializes a Source for that key. Then, while the query is running, that Source will be reused for all calls to that batch key. (GraphQL-Ruby clears the source cache between mutations.)

## Executing the Service Call and Handling the Results

Source classes must implement `#perform(fetch_parameters)` to call the data source, retrieve values, and fulfill each fetch parameter. `#perform` is called by GraphQL internals when it has determined that no further execution is possible without resolving a batch load operation.

In our case, we'll use the batch key (table name) and fetch parameters (IDs) to construct a SQL query. Then, we'll dispatch the query to get results. Finally, we'll get the object for each ID and fulfill the ID.

```ruby
class SQLDatabase < GraphQL::Dataloader::Source
  def initialize(table_name)
    @table_name = table_name
  end

  def perform(ids)
    if ids.any? { |id| !id.is_a?(Numeric) }
      raise ArgumentError, "Invalid IDs: #{ids}"
    end

    if !@table_name.match?(/\A[a-z_]+\Z/)
      raise ArgumentError, "Invalid table name: #{@table_name}"
    end

    # Prepare a query and send it to the database
    query = "SELECT * FROM #{@table_name} WHERE id IN(#{ids.join(",")})"
    results = DatabaseConnection.execute(query)

    # Then, for each of the given `ids`, find the matching result (or `nil`)
    # and call `fulfill(id, result)` to tell GraphQL-Ruby what object to use for that ID.
    ids.each do |id|
      result = results.find { |r| r.id == id }
      fulfill(id, result)
    end
  end
end
```

During `fulfill`, GraphQL-Ruby caches the `id => result` pair. Any subsequent loads to that ID will return the previously-fetched result.

## Background Threads

You can tell GraphQL-Ruby to call `#perform` in a background thread by including {{ "GraphQL::Dataloader::Source::BackgroundThreaded" | api_doc }}. For example:

```ruby
class SQLDatabase < GraphQL::Dataloader::Source
  # This class's `perform` method will be called in the background
  include GraphQL::Dataloader::Source::BackgroundThreaded
end
```

Under the hood, GraphQL-Ruby uses [`Concurrent::Promises::Future`](https://ruby-concurrency.github.io/concurrent-ruby/1.1.7/Concurrent/Promises/Future.html) from [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby/).
