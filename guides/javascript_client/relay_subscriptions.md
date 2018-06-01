---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: Relay Subscriptions
desc: GraphQL subscriptions with GraphQL-Ruby and Relay Modern
index: 3
---

`graphql-ruby-client` includes support for subscriptions with Relay Modern over {% internal_link "Pusher", "/subscriptions/pusher_implementation" %} or {% internal_link "ActionCable", "/subscriptions/action_cable_implementation" %}.

To use it, require `subscriptions/createHandler` and call the function with your client and optionally, your OperationStoreClient.

See the {% internal_link "Subscriptions guide", "/subscriptions/overview" %} for information about server-side setup.

## Pusher

Subscriptions with Pusher require two things:

- A client from the `pusher-js` library
- A `fetchOperation` function for sending the `subscription` operation to the server

### Pusher client

Pass `pusher:` to get Subscription updates over Pusher:

```js
// Require the helper function
var createHandler = require("graphql-ruby-client/subscriptions/createHandler")

// Prepare a Pusher client
var Pusher = require("pusher-js")
var pusherClient = new Pusher(appKey, options)

// Create a Relay Modern-compatible handler
var subscriptionHandler = createHandler({
  pusher: pusherClient,
  fetchOperation: null // TODO!
})

// Create a Relay Modern network with the handler
var network = Network.create(fetchQuery, subscriptionHandler)
```

### fetchOperation function

The `fetchOperation` function can be extracted from your `fetchQuery` function. Its signature is:

```js
// Returns a promise from `fetch`
function fetchOperation(operation, variables, cacheConfig) {
  return fetch(...)
}
```

- `operation`, `variables`, and `cacheConfig` are the first three arguments to the `fetchQuery` function.
- The function should call `fetch` and return the result (a Promise of a `Response`).

For example, `Environment.js` may look like:

```js
// This function sends a GraphQL query to the server
const fetchOperation = function(operation, variables, cacheConfig) {
  const bodyValues = {
    variables,
    operationName: operation.name,
  }
  const useStoredOperations = process.env.NODE_ENV === "production"
  if (useStoredOperations) {
    // In production, use the stored operation
    bodyValues.operationId = OperationStoreClient.getOperationId(operation.name)
  } else {
    // In development, use the query text
    bodyValues.query = operation.text
  }
  return fetch('http://localhost:3000/graphql', {
    method: 'POST',
    opts: {
      credentials: 'include',
    },
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(bodyValues),
  })
}

// `fetchQuery` uses `fetchOperation`, but returns a Promise of JSON
const fetchQuery = (operation, variables, cacheConfig, uploadables) => {
  return fetchOperation(operation, variables, cacheConfig).then(response => {
    return response.json()
  })
}

// Subscriptions uses the same `fetchOperation` function for initial subscription requests
const subscriptionHandler = createHandler({pusher: pusherClient, fetchOperation: fetchOperation})
// Combine them into a `Network`
const network = Network.create(fetchQuery, subscriptionHandler)
```

Since `OperationStoreClient` is in the `fetchOperation` function, it will apply to all GraphQL operations.

## ActionCable

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
