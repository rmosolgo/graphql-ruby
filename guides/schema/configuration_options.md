---
title: Schema — Configuration Options
---

Many things can be added to a GraphQL schema. They fall into a few categories:

- Data entry points: `query`, `mutation`, `subscription`
- Manually adding types: `orphan_types`
- Execution functions: `resolve_type`, `id_from_object`, `object_from_id`
- Security options: `max_depth`, `max_complexity`
- Middleware: `middleware`
- Query analyzers: `query_analyzer`
- Execution strategies: `query_execution_strategy`, `mutation_execution_strategy`, `subscription_execution_strategy`

## Data Entry Points

`query`, `mutation` and `subscriptions` are [root-level](http://graphql.org/learn/schema/#the-query-and-mutation-types) `GraphQL::ObjectType`s.

```ruby
QueryType = GraphQL::ObjectType.define { ... }
MutationType = GraphQL::ObjectType.define { ... }
SubscriptionType = GraphQL::ObjectType.define { ... }

GraphQL::Schema.define do
  # required
  query QueryType
  # optional
  mutation MutationType
  subscription SubscriptionType
end
```


## Orphan Types

The schema builds its type system by traversing its data entry points. In some cases, types should be present in the schema but aren't available via traversal, so you have to add them yourself.

The clearest case of this is when a type implements an interface, but isn't a return type of any other field. Since it's not the return type of a field, it might not be found by traversal, so you can add it in `orphan_types`:

```ruby
GraphQL::Schema.define do
  # ...
  # Make sure these types are present in the schema:
  orphan_types [AudioType, VideoType, ImageType]
end
```

It's OK to add a type to `orphan_types` even if it's already in the schema.

## Execution Functions

During execution, a GraphQL schema may need help from you, which you can provide in these hooks:

- `resolve_type(obj, ctx)`: When we have a member of an interface or union, which object type should we use?
- `id_from_object(object, type, ctx)` (Relay only): Generate a unique ID for `object`
- `object_from_id(id, ctx)` (Relay only): Given a unique ID `id`, return the object which it identifies

These hooks are provided as objects that respond to `#call`, for example, a `Proc` literal:

```ruby
GraphQL::Schema.define do
  # Hooks for query execution:
  resolve_type -> (obj, ctx) { ... }
  id_from_object -> (obj, type, ctx) { ... }
  object_from_id -> (id, ctx) { ... }
end
```

See ["Object Identification"]({{ site.baseurl }}/relay/object_identification) for more information about Relay IDs.

## Security Options

These options can prevent execution of malicious queries.

```ruby
GraphQL::Schema.define do
  # Prevent excessively deep or complex queries
  max_depth 8
  max_complexity 120
end
```

See ["Security"]({{ site.baseurl }}/queries/security) for more information.

## Middleware

You can use _middleware_ to affect the evaluation of fields in your schema. They function like `before_action`s and `after_action`s in Rails controllers.

A middleware is any object that responds to `#call(*args, next_middleware)`. Inside that method, it should either:

- send `call` to the next middleware to continue the evaluation; or
- return a value to end the evaluation early.

Middlewares' `#call` is invoked with several arguments:

- `parent_type` is the type whose field is being accessed
- `parent_object` is the object being exposed by that type
- `field_definition` is the definition for the field being accessed
- `field_args` is the hash of arguments passed to the field
- `query_context` is the context object passed throughout the query
- `next_middleware` represents the execution chain. Call `#call` to continue evalution.

Add a middleware to a schema by adding to the `#middleware` array.

### Example: Authorization

This middleware only continues evaluation if the `current_user` is permitted to read the target object:

```ruby
class AuthorizationMiddleware
  def call(parent_type, parent_object, field_definition, field_args, query_context, next_middleware)
    current_user = query_context[:current_user] # passed in when creating the query
    if current_user && current_user.can_read?(parent_object)
      # This user is authorized, so continue execution
      next_middleware.call
    else
      # Silently halt execution
      nil
    end
  end
end
```

Then, add the middleware to your schema:

```ruby
GraphQL::Schema.define do
  middleware AuthorizationMiddleware.new
end
```

Now, all field access will be wrapped by that authorization routine.

## Query Analyzers

Query analyzers are like middleware for the validation phase. They're called at each node of the query's internal representation (see `GraphQL::InternalRepresentation::Node`). If they return a `GraphQL::AnalysisError` (or an array of those errors), the query won't be run and the error will be added to the response's `errors` key.

The minimal API is `.call(memo, visit_type, internal_representation_node)`. For example:

```ruby
ast_node_logger = -> (memo, visit_type, internal_representation_node) {
  if visit_type == :enter
    puts "Visiting #{internal_representation_node.name}!"
  end
}
MySchema.query_analyzers << ast_node_logger
```

Whatever `.call(...)` returns will be passed as `memo` for the next visit.

The analyzer can implement a few __other methods__. If they're present, they'll be called:

- `.initial_value(query)` will be called to generate an initial value for `memo`
- `.final_value(memo)` will be called _after_ visiting the the query

If the last value of `memo` (or the return of `.final_value`) is a `GraphQL::AnalysisError`, the query won't be executed and the error will be added to the `errors` key of the response.

`graphql-ruby` includes a few query analyzers:

- `GraphQL::Analysis::QueryDepth` and `GraphQL::Analysis::QueryComplexity` for inspecting query depth and complexity
- `GraphQL::Analysis::MaxQueryDepth` and `GraphQL::Analysis::MaxQueryComplexity` are used internally to implement `max_depth:` and `max_complexity:` options

## Execution Strategies

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
  query_execution_strategy CustomQueryExecutionStrategy
end
```
