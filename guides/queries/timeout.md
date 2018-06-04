---
title: Timeout
layout: guide
doc_stub: false
search: true
section: Queries
desc: Cutting off GraphQL execution
index: 5
---

You can apply a timeout to query execution with `TimeoutMiddleware`. For example:

```ruby
class MySchema < GraphQL::Schema
  middleware(GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2))
end
```

After `max_seconds`, no new fields will be resolved. Instead, errors will be added to the `errors` key for fields that weren't resolved.

__Note__ that this _does not interrupt_ field execution (doing so is [buggy](http://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/)). If you're making external calls (eg, HTTP requests or database queries), make sure to use a library-specific timeout for that operation (eg, [Redis timeout](https://github.com/redis/redis-rb#timeouts), [Net::HTTP](https://ruby-doc.org/stdlib-2.4.1/libdoc/net/http/rdoc/Net/HTTP.html)'s `ssl_timeout`, `open_timeout`, and `read_timeout`).

To log the error, pass a block to the middleware:

```ruby
class MySchema < GraphQL::Schema
 middleware(GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2) do |err, query|
   Rails.logger.info("GraphQL Timeout: #{query.query_string}")
 end)
end
```
