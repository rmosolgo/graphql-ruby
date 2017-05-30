---
layout: guide
search: true
section: Fields
title: Introduction
desc: Always limit lists of items
index: 4
---

## List Fields

Always limit the number of items which can be returned from a list field. For example, use a `limit:` argument and make sure it's not too big:

```ruby
field :items, types[ItemType] do
  argument :limit, types.Int, default_value: 20
  resolve ->(obj, args, ctx) {
    # Cap the number of items at 30
    limit = [args[:limit], 30].min
    obj.items.limit(limit)
  }
end
```

This way, you won't hit your database for 1000 items!

## Relay Connections

Relay connections accept a [`max_page_size` option]({{ site.baseurl }}/relay/connections.html#maximum-page-size) which limits the number of nodes.
