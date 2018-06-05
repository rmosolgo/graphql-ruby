---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Overview
desc: Introduction to Subscriptions in GraphQL-Ruby
index: 0
---

_Subscriptions_ allow GraphQL clients to observe specific events and receive updates from the server when those events occur. This supports live updates, such as websocket pushes. Subscriptions introduce several new concepts:

- The __Subscription type__ is the entry point for subscription queries
- __Triggers__ begin the update process
- The __Implementation__ provides application-specific methods for executing & delivering updates.

### Subscription Type

`subscription` is an entry point to your GraphQL schema, like `query` or `mutation`. It is defined by your `SubscriptionType`, a root-level `GraphQL::Schema::Object`.

Read more in the {% internal_link "Subscription Type guide", "subscriptions/subscription_type" %}.

### Triggers

After an event occurs in our application, _triggers_ begin the update process by sending a name and payload to GraphQL.

Read more in the {% internal_link "Triggers guide","subscriptions/triggers" %}.

### Implementation

Besides the GraphQL component, your application must provide some subscription-related plumbing, for example:

- __state management__: How does your application keep track of who is subscribed to what?
- __transport__: How does your application deliver payloads to clients?
- __queueing__: How does your application distribute the work of re-running subscription queries?

Read more in the {% internal_link "Implementation guide", "subscriptions/implementation" %} or check out the {% internal_link "ActionCable implementation", "subscriptions/action_cable_implementation" %} or {% internal_link "Pusher implementation", "subscriptions/pusher_implementation" %}.
