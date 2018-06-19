---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Subscription Type
desc: The root type for subscriptions
index: 1
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
class Types::SubscriptionType < GraphQL::Schema::Object
  field :post_was_published, Types::PostType, null: false,
    description: "A post was published to the blog"
  # ...
end
```

Then, add it as the subscription root with `subscription(...)`:

```ruby
# app/graphql/my_schema.rb
class MySchema < GraphQL::Schema
  query(Types::QueryType)
  # ...
  # Add Subscription to
  subscription(Types::SubscriptionType)
end
```

See {% internal_link "Implementing Subscriptions","subscriptions/implementation" %} for more about actually delivering updates.

## Authorizing Subscriptions

When a client first sends a `subscription` operation, the root fields are resolved, so their corresponding methods are called, for example:

```ruby
class Types::SubscriptionType < GraphQL::Schema::Object
  field :post_was_published, Types::PostType, null: false,
    description: "A post was published to the blog" do
      argument :topic, Types::PostTopic, required: true
    end

  def post_was_published(topic:)
    # This will be called on the initial request
  end
end
```

During that method, you can raise an error to _prevent_ establishing the subscription. For example:

```ruby
def post_was_published(topic:)
  if context[:viewer].can_subscribe_to?(topic)
    # Allow the request
  else
    raise GraphQL::ExecutionError.new("Can't subscribe to this topic: #{topic}")
  end
end
```

If the error is raised, it will be added to the response's `"errors"` key and the subscription won't be created.

The return value of the method is not used; only the raised error affects the behavior of the subscription.
