---
layout: guide
search: true
section: Subscriptions
title: Triggers
desc: Sending updates from your application to GraphQL
index: 2
experimental: true
---

From your application, you can push updates to GraphQL clients with `.trigger`.

Events are triggered _by name_, and the name must match fields on your {% internal_link "Subscription Type","subscriptions/subscription_type" %}

```ruby
# Update the system with the new blog post:
MySchema.subscriptions.trigger("postAdded", {}, new_post)
```

The arguments are:

- `name`, which corresponds to the field on subscription type
- `arguments`, which corresponds to the arguments on subscription type (for example, if you subscribe to comments on a certain post, the arguments would be `{postId: comment.post_id}`.)
- `object`, which will be the root object of the subscription update
- `scope:` (not shown) for implicitly scoping the clients who will receive updates.
