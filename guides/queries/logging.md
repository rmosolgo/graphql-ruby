# Logging

At runtime, GraphQL-Ruby will output debug information using [GraphQL::Query#logger](rdoc-ref:GraphQL::Query#logger). By default, this uses `Rails.logger`. To see output, make sure `config.log_level = :debug` is set. (This information isn't meant for production logs.)

You can configure a custom logger with [GraphQL::Schema.default_logger](rdoc-ref:GraphQL::Schema.default_logger), for example:

```ruby
class MySchema < GraphQL::Schema
  # This logger will be used by queries during execution:
  default_logger MyCustomLogger.new
end
```

You can also pass `context[:logger]` to provide a logger during execution.
