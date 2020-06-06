---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Implementation
desc: Subscription execution and delivery
index: 3
---

The {{ "GraphQL::Subscriptions" | api_doc }} plugin is a base class for implementing subscriptions.

Each method corresponds to a step in the subscription lifecycle. See the API docs for method-by-method documentation: {{ "GraphQL::Subscriptions" | api_doc }}.

Also, see the {% internal_link "Pusher implementation guide", "subscriptions/pusher_implementation" %}, the {% internal_link "Ably implementation guide", "subscriptions/ably_implementation" %}, the {% internal_link "ActionCable implementation guide", "subscriptions/action_cable_implementation" %} or {{ "GraphQL::Subscriptions::ActionCableSubscriptions" | api_doc }} docs for an example implementation.

## Considerations

Every Ruby application is different, so consider these points when implementing subscriptions:

- Is your application single-process or multiprocess? Single-process applications can store state in memory while multiprocess applications need a message broker to keep all processes up-to-date.
- What components of your application can be used for persistence and message passing?
- How will you deliver push updates to subscribed clients? (For example, websockets, ActionCable, Pusher, webhooks, or something else?)
- How will you handle [thundering herd](https://en.wikipedia.org/wiki/Thundering_herd_problem)s? When an event is triggered, how will you manage database access to update clients without swamping your system?

## Broadcasts

GraphQL-Ruby 1.11+ introduced a new algorithm for tracking subscriptions and delivering updates, _broadcasts_. This could result in __breaking changes__ for systems that assumed that every subscription would be re-evaluated in isolation.

A broadcast is a subscription update which is executed _once_, then delivered to _any number_ of subscribers. Broadcasts have several performance advantages:

- __Less GraphQL runtime__: since updates are only evaluated _once_, regardless of the number of subscribers, your server spends less time resolving GraphQL queries.
- __Less pub/sub overhead__: since identical messages can be routed over the same channels, you can use one publish operation to update any number of subscribers.

GraphQL-Ruby determines which subscribers can receive a broadcast by inspecting:

- __Query string__. Only exactly-matching query strings will receive the same broadcast.
- __Variables__. Only exactly-matching variable values will receive the same broadcast.
- __Field and Arguments__ given to `.trigger`. They must match the ones initially sent when subscribing. (Subscriptions always worked this way.)
- __Subscription scope__. Only clients with exactly-matching subscription scope can receive the same broadcasts.

So, take care to {% internal_link "set subscription_scope", "subscriptions/subscription_classes#scope" %} whenever a subscription should be implicitly scoped!
