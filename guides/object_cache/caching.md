---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Caching Results
desc: Configuration options for caching objects and fields
index: 2
---

`GraphQL::Enterprise::ObjectCache` supports several different caching configurations for objects and fields. To get started, include the extension in your base object class and base field class and use `cacheable(...)` to set up the default cache behavior:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  include GraphQL::Enterprise::ObjectCache::ObjectIntegration
  cacheable(...) # see below
  # ...
end
```

```ruby
# app/graphql/types/base_field.rb
class Types::BaseField < GraphQL::Schema::Field
  include GraphQL::Enterprise::ObjectCache::FieldIntegration
  cacheable(...) # see below
  # ...
end
```
