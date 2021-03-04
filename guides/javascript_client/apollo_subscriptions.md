---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: Apollo Subscriptions
desc: GraphQL subscriptions with GraphQL-Ruby and Apollo Client
index: 2
---

GraphQL-Ruby's JavaScript client includes four kinds of support for Apollo Client:

- Apollo 2.x:
  - [Overview](#apollo-2)
  - [Pusher](#apollo-2--pusher)
  - [Ably](#apollo-2--ably)
  - [ActionCable](#apollo-2--actioncable)
- Apollo 1.x:
  - [Overview](#apollo-1)
  - [Pusher](#apollo-1--pusher)
  - [ActionCable](#apollo-1--actioncable)

## Apollo 2

Apollo 2 is supported by implementing Apollo Links.

## Apollo 2 -- Pusher

`graphql-ruby-client` includes support for subscriptions with Pusher and ApolloLink.

To use it, add `PusherLink` before your `HttpLink`.

For example:

```js
// Load Apollo stuff
import { ApolloLink } from 'apollo-link';
import { ApolloClient } from 'apollo-client';
import { HttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';

// Load PusherLink from graphql-ruby-client
import PusherLink from 'graphql-ruby-client/subscriptions/PusherLink';

// Load Pusher and create a client
import Pusher from "pusher-js"
var pusherClient = new Pusher("your-app-key", { cluster: "us2" })

// Make the HTTP link which actually sends the queries
const httpLink = new HttpLink({
  uri: '/graphql',
  credentials: 'include'
});

// Make the Pusher link which will pick up on subscriptions
const pusherLink = new PusherLink({pusher: pusherClient})

// Combine the two links to work together
const link = ApolloLink.from([pusherLink, httpLink])

// Initialize the client
const client = new ApolloClient({
  link: link,
  cache: new InMemoryCache()
});
```

This link will check responses for the `X-Subscription-ID` header, and if it's present, it will use that value to subscribe to Pusher for future updates.

If you're using {% internal_link "compressed payloads", "/subscriptions/pusher_implementation#compressed-payloads" %}, configure a `decompress:` function, too:

```javascript
// Add `pako` to the project for gunzipping
import pako from "pako"

const pusherLink = new PusherLink({
  pusher: pusherClient,
  decompress: function(compressed) {
    // Decode base64
    const data = atob(compressed)
      .split('')
      .map(x => x.charCodeAt(0));
    // Decompress
    const payloadString = pako.inflate(new Uint8Array(data), { to: 'string' });
    // Parse into an object
    return JSON.parse(payloadString);
  }
})
```

## Apollo 2 -- Ably

`graphql-ruby-client` includes support for subscriptions with Ably and ApolloLink.

To use it, add `AblyLink` before your `HttpLink`.

For example:

```js
// Load Apollo stuff
import { ApolloLink } from 'apollo-link';
import { ApolloClient } from 'apollo-client';
import { HttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';
// Load Ably subscriptions link
import AblyLink from 'graphql-ruby-client/subscriptions/AblyLink'
// Load Ably and create a client
const Ably = require("ably")
const ablyClient = new Ably.Realtime({ key: "your-app-key" })

// Make the HTTP link which actually sends the queries
const httpLink = new HttpLink({
  uri: '/graphql',
  credentials: 'include'
});

// Make the Ably link which will pick up on subscriptions
const ablyLink = new AblyLink({ably: ablyClient})

// Combine the two links to work together
const link = ApolloLink.from([ablyLink, httpLink])

// Initialize the client
const client = new ApolloClient({
  link: link,
  cache: new InMemoryCache()
});
```

This link will check responses for the `X-Subscription-ID` header, and if it's present, it will use that value to subscribe to Ably for future updates.

For your __app key__, make a key with "Subscribe" and "Presence" privileges and use that:

{{ "/javascript_client/ably_key.png" | link_to_img:"Ably Subscription Key Privileges" }}

## Apollo 2 -- ActionCable

`graphql-ruby-client` includes support for subscriptions with ActionCable and ApolloLink.

To use it, construct a split link that routes:

- subscription queries to an `ActionCableLink`; and
- other queries to an `HttpLink`

For example:

```js
import { ApolloLink } from 'apollo-link';
import { ApolloClient } from 'apollo-client';
import { HttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { createConsumer } from '@rails/actioncable';
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink';

const cable = createConsumer()

const httpLink = new HttpLink({
  uri: '/graphql',
  credentials: 'include'
});

const hasSubscriptionOperation = ({ query: { definitions } }) => {
  return definitions.some(
    ({ kind, operation }) => kind === 'OperationDefinition' && operation === 'subscription'
  )
}

const link = ApolloLink.split(
  hasSubscriptionOperation,
  new ActionCableLink({cable}),
  httpLink
);

const client = new ApolloClient({
  link: link,
  cache: new InMemoryCache()
});
```

Note that for Rails 5, the ActionCable client package is `actioncable`, not `@rails/actioncable`.

## Apollo 1

`graphql-ruby-client` includes support for Apollo 1 client subscriptions over {% internal_link "Pusher", "/subscriptions/pusher_implementation" %} or {% internal_link "ActionCable", "/subscriptions/action_cable_implementation" %}.

To use it, require `subscriptions/addGraphQLSubscriptions` and call the function with your network interface and transport client (example below).

See the {% internal_link "Subscriptions guide", "/subscriptions/overview" %} for information about server-side setup.

### Apollo 1 -- Pusher

Pass `{pusher: pusherClient}` to use Pusher:

```js
// Load Pusher and create a client
var Pusher = require("pusher-js")
var pusherClient = new Pusher(appKey, options)

// Add subscriptions to the network interface with the `pusher:` options
import addGraphQLSubscriptions from "graphql-ruby-client/subscriptions/addGraphQLSubscriptions"
addGraphQLSubscriptions(myNetworkInterface, {pusher: pusherClient})

// Optionally, add persisted query support:
var OperationStoreClient = require("./OperationStoreClient")
RailsNetworkInterface.use([OperationStoreClient.apolloMiddleware])
```

If you're using {% internal_link "compressed payloads", "/subscriptions/pusher_implementation#compressed-payloads" %}, configure a `decompress:` function, too:

```javascript
// Add `pako` to the project for gunzipping
import pako from "pako"

addGraphQLSubscriptions(myNetworkInterface, {
  pusher: pusherClient,
  decompress: function(compressed) {
    // Decode base64
    const data = btoa(compressed)
    // Decompress
    const payloadString = pako.inflate(data, { to: 'string' })
    // Parse into an object
    return JSON.parse(payloadString);
  }
})
```

### Apollo 1 -- ActionCable

By passing `{cable: cable}`, all `subscription` queries will be routed to ActionCable.

For example:

```js
// Load ActionCable and create a consumer
var ActionCable = require('@rails/actioncable')
var cable = ActionCable.createConsumer()
window.cable = cable

// Load ApolloClient and create a network interface
var apollo = require('apollo-client')
var RailsNetworkInterface = apollo.createNetworkInterface({
 uri: '/graphql',
 opts: {
   credentials: 'include',
 },
 headers: {
   'X-CSRF-Token': $("meta[name=csrf-token]").attr("content"),
 }
});

// Add subscriptions to the network interface
import addGraphQLSubscriptions from "graphql-ruby-client/subscriptions/addGraphQLSubscriptions"
addGraphQLSubscriptions(RailsNetworkInterface, {cable: cable})

// Optionally, add persisted query support:
var OperationStoreClient = require("./OperationStoreClient")
RailsNetworkInterface.use([OperationStoreClient.apolloMiddleware])
```
