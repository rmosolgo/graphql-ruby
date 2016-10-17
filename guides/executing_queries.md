---
title: Executing Queries with `graphql-ruby`

---

After you define your schema, you can evaluate queries with `GraphQL::Schema#execute`.

At the simplest, you can evaluate a query from string against a schema:

```ruby
# let's pretend it's a Rails controller!
query_string = params[:query]
result = MySchema.execute(query_string)
render(json: result)
```

## Variables

If your query contains variables, you can provide their values with the `variables:` keyword.

```ruby
query_string = "query getPost($postId: Int!){ post(id: $postId) { title } }"
result = MySchema.execute(query_string, variables: {"postId" => 2})
```

`variables` keys should be strings, whose names match the variables, without `$`.

## Context

You can pass an arbitrary hash of information into the query with the `context:` keyword.

```ruby
result = MySchema.execute(query_string, context: {current_user: current_user})
```

These values will be accessible by key inside `resolve` functions. For example, this field only returns a value if the current user has high enough permissions:

```ruby
SecretStringField = GraphQL::Field.new do |f|
  f.type !GraphQL::STRING_TYPE
  f.description "A string that's only visible to authorized users"
  f.resolve ->(obj, args, ctx) { ctx[:current_user].authorized? ? obj.secret_string : nil }
end
```

Note that `ctx` is not the _same_ hash that's passed to `GraphQL::Schema#execute`. `ctx` is an instance of `GraphQL::Query::Context`, which exposes the provided hash and may _also_ contain other information about the query.

## Operation name

If your query contains multiple operations, you _must_ pass the operation name with the `operation_name:` keyword:

```ruby
result = MySchema.execute(query_string, operation_name: "getPersonInfo")
```

If you don't, you'll get an error.

## Validation

By default, `graphql-ruby` performs validation on incoming query strings. If you want to disable this, pass `validate: false`. No guarantees it won't blow up :)

```ruby
result = MySchema.execute(query_string, validate: false)
```

## Custom Execution Strategies

`graphql` includes a serial execution strategy, but you can also create custom strategies to support advanced behavior. See `GraphQL::SerialExecution#execute` the required behavior.

Then, set your schema to use your custom execution strategy with `GraphQL::Schema#{query|mutation|subscription}_execution_strategy`

For example:

```ruby
class CustomQueryExecutionStrategy
  def initialize
    # ...
  end

  def execute(operation_name, root_type, query)
    # ...
  end
end

# ... define your types ...

MySchema = GraphQL::Schema.define do
  query MyQueryType
  mutation MyMutationType
  # Use your custom strategy:
  query_execution_strategy = CustomQueryExecutionStrategy
```
