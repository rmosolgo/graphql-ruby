# Async Source Execution

`AsyncDataloader` will run [GraphQL::Dataloader::Source#fetch](rdoc-ref:GraphQL::Dataloader::Source#fetch) calls in parallel, so that external service calls (like database queries or network calls) don't have to wait in a queue.

To use `AsyncDataloader`, hook it up in your schema _instead of_ `GraphQL::Dataloader`:

```diff
- use GraphQL::Dataloader
+ use GraphQL::Dataloader::AsyncDataloader
```

__Also__, add [the `async` gem](https://github.com/socketry/async) to your project, for example:

```
bundle add async
```

Now, [GraphQL::Dataloader::AsyncDataloader](rdoc-ref:GraphQL::Dataloader::AsyncDataloader) will create `Async::Task` instances instead of plain `Fiber`s and the `async` gem will manage parallelism.

For a demonstration of this behavior, see: [https://github.com/rmosolgo/rails-graphql-async-demo](https://github.com/rmosolgo/rails-graphql-async-demo)

_You can also implement [manual parallelism](/dataloader/parallelism) using `dataloader.yield`._

## Rails

For Rails, you'll need **Rails 7.1**, which properly supports fiber-based concurrency, and you'll also want to configure Rails to use Fibers for isolation:

```ruby
class Application < Rails::Application
  # ...
  config.active_support.isolation_level = :fiber
end
```
### ActiveRecord Connections

You can use Dataloader's [Fiber lifecycle hooks](/dataloader/dataloader#fiber-lifecycle-hooks) to improve ActiveRecord connection handling:

- In Rails < 7.2, connections are not reused when a Fiber exits; instead, they're only reused when a request or background job finishes. You can add manual `release_connection` calls to improve this.
- With `isolation_level = :fiber`, new Fibers don't inherit `connected_to ...` settings from their parent fibers.

Altogether, it can be improved like this:

```ruby
def get_fiber_variables
  vars = super
  # Collect the current connection config to pass on:
  vars[:connected_to] = {
    role: ActiveRecord::Base.current_role,
    shard: ActiveRecord::Base.current_shard,
    prevent_writes: ActiveRecord::Base.current_preventing_writes
  }
  vars
end

def set_fiber_variables(vars)
  connection_config = vars.delete(:connected_to)
  # Reset connection config from the parent fiber:
  ActiveRecord::Base.connecting_to(**connection_config)
  super(vars)
end

def cleanup_fiber
  super
  # Release the current connection
  ActiveRecord::Base.connection_pool.release_connection
end
```

Modify the example according to your database configuration and abstract class hierarchy.

### Request state (`CurrentAttributes` and friends)

With `isolation_level = :fiber`, everything Rails keeps in `ActiveSupport::IsolatedExecutionState` is per Fiber, so a new Fiber also starts with empty `ActiveSupport::CurrentAttributes` (for example, `Current.user`) and an empty `ActiveSupport::ExecutionContext`. Dataloader only copies `Thread.current[...]` values into new Fibers (see `get_fiber_variables`), so resolvers and sources that read `Current` will see `nil` unless you pass those values on too.

Rails has no public API that lists the current `CurrentAttributes` instances, so the example below uses `ActiveSupport::ExecutionContext.current_attributes_instances`, which is internal (`:nodoc:`); you can instead list your `CurrentAttributes` classes explicitly. Copy the values rather than sharing the parent's state: AsyncDataloader switches Fibers whenever one waits on IO, so state shared by reference is visible to siblings _in the middle of_ a block. A sibling paused inside `Current.set(...) { ... }`, `Model.where(...).scoping { ... }` or `Model.unscoped { ... }` would otherwise leak its temporary values or relation scope into the queries of the Fiber that runs next.

```ruby
def get_fiber_variables
  vars = super
  vars[:current_attributes] = ActiveSupport::ExecutionContext.current_attributes_instances.values.map { |c| [c.class, c.attributes] }
  vars
end

def set_fiber_variables(vars)
  current_attributes = vars.delete(:current_attributes)
  super(vars)
  # Each Fiber gets its own copy, so a Current.set in one can't show through in another:
  current_attributes.each { |current_class, attributes| current_class.instance.attributes = attributes }
end
```

Because each Fiber holds a copy, a value a Fiber sets lazily (for example, `Current.request_id ||= SecureRandom.uuid`) stays in that Fiber. Set such values before the query runs if every Fiber must see the same one.

### Query cache

Each Fiber leases its own database connection, and Rails gives each connection the query cache of the Fiber that checked it out. So a Fiber starts with an empty, disabled query cache: queries the request already cached run again, and identical queries in sibling Fibers aren't shared. Expect more queries per request than with the non-async Dataloader.

### GraphQL::Batch

If a schema also uses [GraphQL::Batch](https://github.com/Shopify/graphql-batch), its loaders aren't safe to suspend: a loader is marked as resolving while it runs `#perform`, so if that Fiber waits on IO, another Fiber calling `Promise#sync` on the same loader finds it still pending and raises `Promise::BrokenError`. Run batch loaders without yielding to the scheduler:

```ruby
module BlockingBatchLoaderResolve
  def resolve
    Fiber.blocking { super }
  end
end

GraphQL::Batch::Loader.prepend(BlockingBatchLoaderResolve)
```

## Other Options

You can also manually implement parallelism with Dataloader. See the [Dataloader Parallelism](/dataloader/parallelism) guide for details.
