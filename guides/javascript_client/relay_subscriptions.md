---
layout: guide
search: true
section: JavaScript Client
title: Relay Subscriptions
desc: GraphQL subscriptions with GraphQL-Ruby and Relay Modern
index: 3
---

`graphql-ruby-client` includes support for subscriptions with ActionCable and Relay Modern.

To use it, require `subscriptions/createHandler` and call the function with your ActionCable consumer and optionally, your OperationStoreClient.

With this configuration, `subscription` queries will be routed to ActionCable.

For example:

```js
// Require the helper function
var createHandler = require("graphql-ruby-client/subscriptions/createHandler")
// Optionally, load your OperationStoreClient
var OperationStoreClient = require("./OperationStoreClient")

// Create a Relay Modern-compatible handler
var subscriptionHandler = createHandler({
  cable: cable,
  operations: OperationStoreClient,
})

// Create a Relay Modern network with the handler
var network = Network.create(fetchQuery, subscriptionHandler)
```

See the Subscriptions guide for information about server-side setup.
