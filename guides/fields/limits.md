---
layout: guide
doc_stub: false
search: true
section: Fields
title: Limits
desc: Always limit lists of items
index: 4
---

## List Fields

Always limit the number of items which can be returned from a list field. For example, use a `limit:` argument and make sure it's not too big. The `prepare:` function provides a convenient place to cap the number of items:

```ruby
field :items, types[ItemType] do
  # Cap the number of items at 30
  argument :limit, types.Int, default_value: 20, prepare: ->(limit, ctx) {[limit, 30].min}
  resolve ->(obj, args, ctx) {
    obj.items.limit(args[:limit])
  }
end
```

This way, you won't hit your database for 1000 items!

## Relay Connections

Relay connections accept a {% internal_link "`max_page_size` option","/relay/connections.html#maximum-page-size" %} which limits the number of nodes.
