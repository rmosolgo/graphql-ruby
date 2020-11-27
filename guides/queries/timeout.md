---
title: Timeout
layout: guide
doc_stub: false
search: true
section: Queries
desc: Cutting off GraphQL execution
index: 5
---

You can apply a timeout to query execution with the `GraphQL::Schema::Timeout` plugin. For example:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Schema::Timeout, max_seconds: 2
end
```

After `max_seconds`, no new fields will be resolved. Instead, errors will be added to the `errors` key for fields that weren't resolved.

__Note__ that this _does not interrupt_ field execution (doing so is [buggy](https://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/)). If you're making external calls (eg, HTTP requests or database queries), make sure to use a library-specific timeout for that operation (eg, [Redis timeout](https://github.com/redis/redis-rb#timeouts), [Net::HTTP](https://ruby-doc.org/stdlib-2.4.1/libdoc/net/http/rdoc/Net/HTTP.html)'s `ssl_timeout`, `open_timeout`, and `read_timeout`).

To log the error, provide a subclass of `GraphQL::Schema::Timeout` with an overridden `handle_timeout` method:

```ruby
class MyTimeout < GraphQL::Schema::Timeout
  def handle_timeout(error, query)
    Rails.logger.warn("GraphQL Timeout: #{error.message}: #{query.query_string}")
  end
end

class MySchema < GraphQL::Schema
  use MyTimeout, max_seconds: 2
end
```

### Validation

Queries can originate from a user, and may be crafted in a manner to take a long time to validate against the schema.

It is possible to set an upper bound on how long the static validation rules are allowed to run before returning a validation timeout error. The default is no timeout.

For example:

```ruby
class MySchema < GraphQL::Schema
  validate_timeout 10
end
```
