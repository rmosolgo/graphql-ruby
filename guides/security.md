---
title: GraphQL Security
---

Since a GraphQL endpoint provides arbitrary access to your application, you should employ safeguards to prevent large queries from swamping your system.

## Limiting lists of items

Always limit the number of items which can be returned from a list field. For example, use a `limit:` argument and make sure it's not too big:

```ruby
field :items, types[ItemType] do
  argument :limit, types.Int, default_value: 20
  resolve ->(obj, args, ctx) {
    # Cap the number of items at 30
    limit = [args[:limit], 30].min
    obj.items.limit(limit)
  }
end
```

This way, you won't hit your database for 1000 items!

## Enforce a timeout

You can apply a timeout to query execution with `TimeoutMiddleware`. For example:

```ruby
MySchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2)
```

After `max_seconds`, no new fields will be resolved. Instead, errors will be added to the `errors` key for fields that weren't resolved.

__Note__ that this does not _interrupt_ field execution. If you're making external calls (eg, HTTP requests or database queries), make sure to use a "lower level" timeout for the specific operation.

To log the error, pass a block to the middleware:

```ruby
MySchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2) do |err, query|
  Rails.logger.info("GraphQL Timeout: #{query.query_string}")
end
```

## Prevent complex queries

Fields have a "complexity" value which can be configured in their definition. It can be a constant (numeric) value, or a proc. It can be defined as a keyword _or_ inside the configuration block. For example:

```ruby
# Constant complexity:
field :top_score, types.Int, complexity: 10

# Dynamic complexity:
field :top_scorers, types[PlayerType] do
  argument :limit, types.Int, default_value: 5
  complexity ->(ctx, args, child_complexity) {
    if ctx[:current_user].staff?
      # no limit for staff users
      0
    else
      # `child_complexity` is the value for selections
      # which were made on the items of this list.
      #
      # We don't know how many items will be fetched because
      # we haven't run the query yet, but we can estimate by
      # using the `limit` argument which we defined above.
      args[:limit] * child_complexity
    end
  }
end
```

Then, define your `max_complexity` at the schema-level:

```ruby
MySchema = GraphQL::Schema.define do
 # ...
 max_complexity 100
end
```

Or, at the query-level, which overrides the schema-level setting:

```ruby
MySchema.execute(query_string, max_complexity: 100)
```

Using `nil` will disable the validation:

```ruby
# 😧 Anything goes!
MySchema.execute(query_string, max_complexity: nil)
```

To get a feeling for complexity of queries in your system, you can use the `QueryComplexity` query reducer. Hook it up to log out values from each query:

```ruby
log_query_complexity = GraphQL::Analysis::QueryComplexity.new { |query, complexity| Rails.logger.info("[GraphQL Query Complexity] #{complexity}  | staff? #{query.context[:current_user].staff?}")}
MySchema.query_analyzers << log_query_complexity
```

## Prevent deeply-nested queries

You can also reject queries based on the depth of their nesting. You can define `max_depth` at schema-level or query-level:

```ruby
# Schema-level:
MySchema = GraphQL::Schema.define do
  # ...
  max_depth 10
end

# Query-level, which overrides the schema-level setting:
MySchema.execute(query_string, max_depth: 10)
```

You can use `nil` to disable the validation:

```ruby
# This query won't be validated:
MySchema.execute(query_string, max_depth: nil)
```

To get a feeling for depth of queries in your system, you can use the `QueryDepth` query reducer. Hook it up to log out values from each query:

```ruby
log_query_depth = GraphQL::Analysis::QueryDepth.new { |query, depth| Rails.logger.info("[GraphQL Query Depth] #{depth} || staff?  #{query.context[:current_user].staff?}")}
MySchema.query_analyzers << log_query_depth
```

## Only execute predefined queries

If you don't want to accept arbitrary queries from the "outside world", you can cache queries on the server and fetch them in response to specific requests.

For example, you could store parsed `GraphQL::Language::Nodes::Document` objects in a cache:

```ruby
parsed_document = GraphQL.parse(query_string)
operation_name = parsed_document.definitions.first.name
MyCache.set(operation_name, parsed_document)
```

Then, later, you could fetch the document from storage and use it to run a query:

```ruby
# later ...
operation_name = params[:operation_name]
document = MyCache.get(operation_name)
if document.nil?
  raise("No stored operation called #{operation_name}")
else
  # use `document` instead of a query string:
  MySchema.execute(document, context: { ... })
end
```

This way, no unknown queries are evaluated by the server.
