---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Subscription Classes
desc: Subscription resolvers for pushing updates to clients
index: 1
---

You can extend {{ "GraphQL::Schema::Subscription" | api_doc }} to create fields that can be subscribed to.

## Add a base class

First, add a base class for your application. You can hook up your base classes there:

```ruby
# app/graphql/subscriptions/base_subscription.rb
class Subscriptions::BaseSubscription < GraphQL::Schema::Subscription
  # Hook up base classes
  object_class Types::BaseObject
  field_class Types::BaseField
  argument_class Types::BaseArgument
end
```

## Extend the base class and hook it up

Define a class for each subscribable event in your system. For example, if you run a chat room, you might publish events whenever messages are posted in a room:

```ruby
# app/graphql/subscriptions/message_was_posted.rb
class Subscriptions::MessageWasPosted < Subscriptions::BaseSubscription
end
```

Then, hook up the new class to the {% internal_link "Subscription root type", "subscriptions/subscription_type" %} with the `subscription:` option:

```ruby
class Types::SubscriptionType < Types::BaseObject
  field :message_was_posted, subscription: Subscriptions::MessageWasPosted
end
```

Now, it will be accessible as:

```graphql
subscription {
  messageWasPosted(roomId: "abcd") {
    # ...
  }
}
```

## Arguments

Subscription fields take {% internal_link "arguments", "/fields/arguments" %} just like normal fields. They also accept a {% internal_link "`loads:` option", "/mutations/mutation_classes#auto-loading-arguments" %} just like mutations. For example:

```ruby
class Subscriptions::MessageWasPosted < Subscriptions::BaseSubscription
  # `room_id` loads a `room`
  argument :room_id, ID, required: true, loads: Types::RoomType

  # It's passed to other methods as `room`
  def subscribe(room:)
    # ...
  end

  def update(room:)
    # ...
  end
end
```

This can be invoked as

```graphql
subscription($roomId: ID!) {
  messageWasPosted(roomId: $roomId) {
    # ...
  }
}
```

If a field is `required: true`, but the ID doesn't find an object, then the subscription will be unsubscribed (with `#unsubscribe`, see below).

## Fields

Like mutations, you can use a generated return type for subscriptions. When you add `field(...)`s to a subscription, they'll be added to the subscription's generated return type. For example:

```ruby
class Subscriptions::MessageWasPosted < Subscriptions::BaseSubscription
  field :room, Types::RoomType, null: true
  field :message, Types::MessageType, null: true
end
```

will generate:

```graphql
type MessageWasPostedPayload {
  room: Room!
  message: Message!
}
```

Which you can use in queries like:

```graphql
subscription($roomId: ID!) {
  messageWasPosted(roomId: $roomId) {
    room {
      name
    }
    message {
      author {
        handle
      }
      body
      postedAt
    }
  }
}
```

If you configuure fields with `null: true`, then you can return different data in the initial subscription and the subsequent updates. (See lifecycle methods below.)

Instead of a generated type, you can provide an already-configured type with `payload_type`:

```ruby
# Just return a message
payload_type Types::MessageType
```

(In that case, don't return a hash from `#subscribe` or `#update`, return a `message` object instead.)

## Check Permissions with #authorized?

Suppose a client is subscribing to messages in a chat room:

```graphql
subscription($roomId: ID!) {
  messageWasPosted(roomId: $roomId) {
    message {
      author { handle }
      body
      postedAt
    }
  }
}
```

You can implement `#authorized?` to check that the user has permission to subscribe to these arguments (and receive updates for these arguments), for example:

```ruby
def authorized?(room:)
  context[:viewer].can_read_messages?(room)
end
```

The method may return `false` or raise a `GraphQL::ExecutionError` to halt execution.

This method is called _before_ `#subscribe` and `#update`, described below. This way, if a user's permissions have changed since they subscribed, they won't receive updates unauthorized updates.

Also, if this method fails before calling `#update`, then the client will be automatically unsubscribed (with `#unsubscribe`).

## Initial Subscription with #subscribe

`def subscribe(**args)` is called when a client _first_ sends a `subscription { ... }` request. In this method, you can do a few things:

- Call `super` to register a subscription
- Raise `GraphQL::ExecutionError` to halt and return an error
- Return a value to give the client an initial response
- Return `context.skip` to skip the initial response

You can define this method to add initial responses or perform other logic before subscribing.

### Adding an Initial Response

By default, GraphQL-Ruby returns _nothing_ on an initial subscription. But, you may choose to override this and return a value in `def subscribe`. For example:

```ruby
class Subscriptions::MessageWasPosted < Subscriptions::BaseSubscription
  # ...
  field :room, Types::RoomType, null: true

  def subscribe(room:)
    # authorize, etc ...
    # Return the room in the initial response
    {
      room: room
    }
  end
end
```

Now, a client can get some initial data with:

```graphql
subscription($roomId: ID!) {
  messageWasPosted(roomId: $roomId) {
    room {
      name
      messages(last: 40) {
        # ...
      }
    }
  }
}
```

## Subsequent Updates with #update

After a client has registered a subscription, the application may trigger subscription updates with `MySchema.subscriptions.trigger(...)` (see the {% internal_link "Triggers guide", "/subscriptions/triggers" %} for more). Then, `def update` will be called for each client's subscription. In this method you can:

- Unsubscribe the client with `unsubscribe`
- Return a value with `super` (which returns `object`) or by returning a different value.

### Returning a different object for subscription updates

By default, whatever object you pass to `.trigger(event_name, args, object)` will be used for responding to subscription fields. But, you can return a different object from `#update` to override this:

```ruby
field :queue, Types::QueueType, null: false

# eg, `MySchema.subscriptions.trigger("queueWasUpdated", {name: "low-priority"}, :low_priority)`
def update(name:)
  # Make a Queue object which _represents_ the queue with this name
  queue = JobQueue.new(name)

  # This object was passed to `.trigger`, but we're ignoring it:
  object # => :low_priority

  # return the queue instead:
  { queue: queue }
end
```

## Terminating the subscription with #unsubscribe

Within a subscription method, you may call `unsubscribe` to terminate the client's subscription, for example:

```ruby
def update(room:)
  if room.archived?
    # Don't let anyone subscribe to messages on an archived room
    unsubscribe
  else
    super
  end
end
```

`#unsubscribe` has the following effects:

- The subscription is unregistered from the backend (this is backend-specific)
- The client is told to unsubscribe (this is transport-specific)

`#unsubscribe` does _not_ halt the current update.

Arguments with `loads:` configurations will call `unsubscribe` if they are `required: true` and their ID doesn't return a value. (It's assumed that the subscribed object was deleted.)
