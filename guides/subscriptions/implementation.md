# Implementation

The [GraphQL::Subscriptions](rdoc-ref:GraphQL::Subscriptions) plugin is a base class for implementing subscriptions.

Each method corresponds to a step in the subscription lifecycle. See the API docs for method-by-method documentation: [GraphQL::Subscriptions](rdoc-ref:GraphQL::Subscriptions).

Also, see the [Pusher implementation guide](subscriptions/pusher_implementation), the [Ably implementation guide](subscriptions/ably_implementation), the [ActionCable implementation guide](subscriptions/action_cable_implementation) or [GraphQL::Subscriptions::ActionCableSubscriptions](rdoc-ref:GraphQL::Subscriptions::ActionCableSubscriptions) docs for an example implementation.

## Considerations

Every Ruby application is different, so consider these points when implementing subscriptions:

- Is your application single-process or multiprocess? Single-process applications can store state in memory while multiprocess applications need a message broker to keep all processes up-to-date.
- What components of your application can be used for persistence and message passing?
- How will you deliver push updates to subscribed clients? (For example, websockets, ActionCable, Pusher, webhooks, or something else?)
- How will you handle [thundering herd](https://en.wikipedia.org/wiki/Thundering_herd_problem)s? When an event is triggered, how will you manage database access to update clients without swamping your system?

## Broadcasts

_Broadcasting_ updates to multiple subscribers is supported by GraphQL-Ruby, but requires implementation-specific work, see more in the [Broadcast guide](subscriptions/broadcast).
