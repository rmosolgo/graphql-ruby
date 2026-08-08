# Redis Backend

`OperationStore` can use Redis to store persisted queries. Pass a `redis:` option when adding the plugin:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Pro::OperationStore, redis: Redis.new
end
```

(You can initialize `Redis` with any options you need.)

__Note:__ Be sure that this Redis instance is configured as a _persistent database_, not as a cache. You don't want it to throw away old keys!
