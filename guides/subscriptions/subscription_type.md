---
layout: guide
search: true
section: Subscriptions
title: Subscription Type
desc: The root type for subscriptions
index: 1
experimental: true
---

To enable subscriptions:

- Define `SubscriptionType`
- Add a `subscription` type to your schema
- Hook up the module with `use(GraphQL::Subscription, options)`

For example:

```ruby
# app/graphql/types/subscription_type.rb
Types::SubscriptionType = GraphQL::ObjectType.define do
  name "Subscription"
  field :postAdded, !Types::PostType, "A post was published to the blog"
  # ...
end
```

And:

```ruby
# app/graphql/my_schema.rb
MySchema = GraphQL::Schema.define do
  query(Types::QueryType)
  # ...
  subscription(Types::SubscriptionType)
  use GraphQL::Subscriptions, {
    # options, see below ...
  }
end
```
