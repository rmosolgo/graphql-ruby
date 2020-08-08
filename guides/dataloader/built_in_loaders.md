---
layout: guide
doc_stub: false
search: true
section: Dataloader
title: Built-in loaders
desc: Default batch loaders in GraphQL-Ruby
index: 2
---

Although you'll probably need some {% internal_link "custom loaders", "/dataloader/custom_loaders" %} before long, GraphQL-Ruby ships with a few basic loaders to get you started and serve as examples (you can also [opt out](#opting-out) of them). Follow the links below to see the API docs for each loader:

- {{ "GraphQL::Dataloader::ActiveRecordLoader" | api_doc }} as `dataloader.active_record`
- {{ "GraphQL::Dataloader::HttpLoader" | api_doc }} as `dataloader.http`
- {{ "GraphQL::Dataloader::RedisLoader" | api_doc }} as `dataloader.redis`

## Opting Out

If you don't want to run the built-in loaders, you can pass `default_loaders: false` when hooking up {{ "GraphQL::Dataloader" | api_doc }}:

```ruby
use GraphQL::Dataloader, default_loaders: false
```
