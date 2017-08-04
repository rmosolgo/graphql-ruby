---
layout: guide
search: true
section: Subscriptions
title: Overview
desc: Introduction to Subscriptions in GraphQL-Ruby
index: 0
experimental: true
---

_Subscriptions_ allow GraphQL clients to observe specific events and receive updates from the server when those events occur. This supports live updates, such as websocket pushes. Subscriptions introduce several new concepts:

- The __Subscription type__ is the entry point for subscription queries
- __Triggers__ begin the update process
- The __Store__ manages subscriber state (_who_ subscribed to _what_)
- The __Queue__ runs subscription queries after events happen (eg, ActiveJob)
- The __Transport__ delivers updates to clients

### Subscription Type

`subscription` is an entry point to your GraphQL schema, like `query` or `mutation`. It is defined by your `SubscriptionType`, a root-level `ObjectType`.

Read more in the {% internal_link "Subscription Type guide", "subscriptions/subscription_type" %}.

### Triggers

After an event occurs in our application, _triggers_ begin the update process by sending a name and payload to GraphQL.

Read more in the {% internal_link "Triggers guide","subscriptions/triggers" %}.

### Store

As clients subscribe and unsubscribe, you must keep track of their subscription status. The _Store_ manages this state.

Read more in the {% internal_link "Store guide","subscriptions/store" %}

### Queue

After a trigger, clients must be updated with new data. The _Queue_ evaluates GraphQL queries and delivers the result to clients.

Read more in the {% internal_link "Queue guide","subscriptions/transport" %}

### Transport

Clients must receive data somehow. A _Transport_ is a way to send data to a client (eg, websocket, native push notification, or webhook).

Read more in the {% internal_link "Transport guide","subscriptions/transport" %}
