---
layout: guide
search: true
section: Subscriptions
title: Subscription Type
desc: The root type for subscriptions
index: 1
experimental: true
---

`Subscription` is the entry point for all subscriptions in a GraphQL system. Each field corresponds to an event which may be subscribed to:

```graphql
type Subscription {
  # Triggered whenever a post is added
  postWasPublished: Post
  # Triggered whenever a comment is added;
  # to watch a certain post, provide a `postId`
  commentWasPublished(postId: ID): Comment
}
```

This type is the root for `subscription` operations, for example:

```graphql
subscription {
  postWasPublished {
    # This data will be delivered whenever `postWasPublished`
    # is triggered by the server:
    title
    author {
      name
    }
  }
}
```

To add subscriptions to your system, define an `ObjectType` named `Subscription`:

```ruby
# app/graphql/types/subscription_type.rb
Types::SubscriptionType = GraphQL::ObjectType.define do
  name "Subscription"
  field :postWasPublished, !Types::PostType, "A post was published to the blog"
  # ...
end
```

Then, add it as the subscription root with `subscription(...)`:

```ruby
# app/graphql/my_schema.rb
MySchema = GraphQL::Schema.define do
  query(Types::QueryType)
  # ...
  # Add Subscription to
  subscription(Types::SubscriptionType)
end
```

See {% internal_link "Implementing Subscriptions","subscriptions/implementation" %} for more about actually delivering updates.
