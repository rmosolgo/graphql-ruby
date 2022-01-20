---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - Defer
title: Stream
desc: Using @stream to receive list items one at a time
index: 3
pro: true
---

`@stream` works very much like `@defer`, except it only applies to list fields. When a field has `@stream` and it returns a list, then each item in the list is returned to the client as a patch.

__Note:__ `@stream` was added in GraphQL-Pro 1.21.0 and requires GraphQL-Ruby 1.13.6+.

### Installation

To support `@stream` in your schema, add it with `use GraphQL::Pro::Stream`:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Pro::Stream
end
```

Additionally, you should update your controller to handle deferred parts of the response. See the {% internal_link "@defer setup guide", "defer/setup#sending-streaming-responses" %} for details. (`@stream` uses the same deferral pipeline as `@defer`, so the same setup instructions apply.)

### Usage

After that, you can include `@stream` in your queries, for example:

```ruby
{
  # Send each movie in its own patch:
  nowPlaying @stream {
    title
    director { name }
  }
}
```

If `@stream` is applied to non-list fields, it's ignored.
