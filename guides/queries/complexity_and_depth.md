---
title: Complexity & Depth
layout: guide
doc_stub: false
search: true
section: Queries
desc: Limiting query depth and field selections
index: 4
---

GraphQL-Ruby ships with some validations based on {% internal_link "query analysis", "/queries/ast_analysis" %}. You can customize them as-needed, too.

## Prevent complex queries

Fields have a "complexity" value which can be configured in their definition. It can be a constant (numeric) value, or a proc. If no `complexity` is defined for a field, it will default to a value of `1`. It can be defined as a keyword _or_ inside the configuration block. For example:

```ruby
# Constant complexity:
field :top_score, Integer, null: false, complexity: 10

# Dynamic complexity:
field :top_scorers, [PlayerType], null: false do
  argument :limit, Integer, limit: false, default_value: 5
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
class MySchema < GraphQL::Schema
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

To get a feeling for complexity of queries in your system, you can extend {{ "GraphQL::Analysis::AST::QueryComplexity" | api_doc }}. Hook it up to log out values from each query:

```ruby
class LogQueryComplexityAnalyzer < GraphQL::Analysis::AST::QueryComplexity
  # Override this method to _do something_ with the calculated complexity value
  def result
    complexity = super
    message = "[GraphQL Query Complexity] #{complexity} | staff? #{query.context[:current_user].staff?}"
    Rails.logger.info(message)
  end
end

class MySchema < GraphQL::Schema
  query_analyzer(LogQueryComplexityAnalyzer)
end
```

#### Connection fields

By default, GraphQL-Ruby calculates a complexity value for connection fields by:

- adding `1` for `pageInfo` and each of its subselections
- adding `1` for `count`, `totalCount`, or `total`
- adding `1` for the connection field itself
- multiplying the complexity of other fields by the largest possible page size, which is the greater of `first:` or `last:`, or if neither of those are given it will go through each of `default_page_size`, the schema's `default_page_size`, `max_page_size`, and then the schema's `default_max_page_size`.

    (If no default page size or max page size can be determined, then the analysis crashes with an internal error -- set `default_page_size` or `default_max_page_size` in your schema to prevent this.)

For example, this query has complexity `26`:

```graphql
query {
  author {              # +1
    name                # +1
    books(first: 10) {  # +1
      nodes {           # +10 (+1, multiplied by `first:` above)
        title           # +10 (ditto)
      }
      pageInfo {        # +1
        endCursor       # +1
      }
      totalCount        # +1
    }
  }
}
```

To customize this behavior, implement `def calculate_complexity(query:, nodes:, child_complexity:)` in your base field class, handling the case where `self.connection?` is `true`:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  def calculate_complexity(query:, nodes:, child_complexity:)
    if connection?
      # Custom connection calculation goes here
    else
      super
    end
  end
end
```

## Prevent deeply-nested queries

You can also reject queries based on the depth of their nesting. You can define `max_depth` at schema-level or query-level:

```ruby
# Schema-level:
class MySchema < GraphQL::Schema
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

To get a feeling for depth of queries in your system, you can extend {{ "GraphQL::Analysis::AST::QueryDepth" | api_doc }}. Hook it up to log out values from each query:

```ruby
class LogQueryDepth < GraphQL::Analysis::AST::QueryDepth
  def result
    query_depth = super
    message = "[GraphQL Query Depth] #{query_depth} || staff?  #{query.context[:current_user].staff?}"
    Rails.logger.info(message)
  end
end

class MySchema < GraphQL::Schema
  query_analyzer(LogQueryDepth)
end
```
