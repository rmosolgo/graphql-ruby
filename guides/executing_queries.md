# Executing Queries with `graphql-ruby`

After you define your schema, you can evaluate queries with `GraphQL::Query`.

At the simplest, you can evaluate a query from string against a schema:

```ruby
# let's pretend it's a Rails controller!
query_string = params[:query]
query = GraphQL::Query.new(MySchema, query_string)
render(json: query.result)
```

## Variables

If your query contains variables, you can provide their values with the `variables:` keyword.

```ruby
query_string = "query getPost($postId: !Int){ post(id: $postId) { title } }"
query = GraphQL::Query.new(MySchema, query_string, variables: {"postId" => 2})
query.result
```

`variables` keys should be strings, whose names match the variables, without `$`.

## Context

You can pass an arbitrary hash of information into the query with the `context:` keyword.

```ruby
query = GraphQL::Query.new(MySchema, query_string, context: {current_user: current_user})
query.result
```

These values will be accessible by key inside `resolve` functions. For example, this field only returns a value if the current user has high enough permissions:

```ruby
SecretStringField = GraphQL::Field.new do |f|
  f.type !GraphQL::STRING_TYPE
  f.description "A string that's only visible to authorized users"
  f.resolve -> (obj, args, ctx) { ctx[:current_user].authorized? ? obj.secret_string : nil }
end
```

Note that `ctx` is not the _same_ hash that's passed to `GraphQL::Query.new`. `ctx` is an instance of `GraphQL::Query::Context`, which exposes the provided hash and may _also_ contain other information about the query.

## Operation name

If your query contains multiple operations, you _must_ pass the operation name with the `operation_name:` keyword:

```ruby
query = GraphQL::Query.new(MySchema, query_string, context: {operation_name: "getPersonInfo"})
query.result
```

If you don't, you'll get an error.

## Debug

By default, `GraphQL::Query` rescues any error during execution and puts it in the response's `"errors"` key. You can disable this with `debug: true`, which will cause any error to be raised.

```ruby
query = GraphQL::Query.new(MySchema, query_string, debug: false)
query.result
```

## Validation

By default, `GraphQL::Query` performs validation on incoming query strings. If you want to disable this, pass `validate: false`. No guarantees it won't blow up :)

```ruby
query = GraphQL::Query.new(MySchema, query_string, validate: false)
query.result
```

## Custom Execution Strategies

`graphql` includes a couple of execution strategies, but you can also create custom strategies to support advanced behavior. See `BaseExecution` for the required methods `#initialize` and [`#execute(operation_name, root_type, query)`](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/master/GraphQL/Query/BaseExecution#execute-instance_method)

Then, set your schema to use your custom execution strategy with `#mutation_execution_strategy` or `#query_execution_strategy`

For example:

```
class CustomQueryStrategy
  def initialize
    # ...
  end

  def execute(operation_name, root_type, query)
    # ...
  end
end

# ... define your types ...

MySchema = GraphQL::Schema.new(query: MyQueryType, mutation: MyMutationType)
# Use your custom strategy:
MySchema.query_execution_strategy = CustomQueryStrategy
```
