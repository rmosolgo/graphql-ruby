---
layout: guide
search: true
section: GraphQL Pro - OperationStore
title: Client Workflow
desc: Add clients to the system, then sync their operations with the database.
index: 2
---

To use persisted queries with your client application, you must:

- Set up `OperationStore`, as described in [Getting Started]({{ site.baseurl }}/operation_store/getting_started)
- [Add the client](#add-a-client) to the system
- [Sync operations](#syncing) from the client to the server
- [Send `params[:operationId]`](#client-usage) from the client app

This documentation also touches on [`graphql-pro-js`](https://github.com/rmosolgo/graphql-pro-js), a JavaScript client library for using `OperationStore`.

### Add a Client

Clients are registered via [the UI]({{ site.baseurl }}/operation_store/getting_started#add-routes):

{{ "/operation_store/add_a_client.png" | link_to_img:"Add a Client for Persisted Queries" }}

A default `secret` is provided for you, but you can also enter your own. The `secret` is used for [HMAC authorization](({{ site.baseurl }}/operation_store/authorization)).

(Are you interested in a Ruby API for this? Please {% open_an_issue "OperationStore Ruby API" %} or email `support@graphql.pro`.)

### Syncing

Once a client is registered, it can push queries to the server via [the Sync API]({{ site.baseurl }}/operation_store/getting_started#add-routes).

The easiest way to sync is with `graphql-pro sync`, a command-line tool written in JavaScript: [`graphql-pro-js`](https://github.com/rmosolgo/graphql-pro-js).

In short, it:

- Finds GraphQL queries from `.graphql` files or `relay-compiler` output in the provided `--path`
- Adds an [Authentication header]({{ site.baseurl }}/operation_store/authorization) based on the provided `--client` and `--secret`
- Sends the operations to the provided `--url`
- Generates a JavaScript module into the provided `--outfile`

For example:

{{ "/operation_store/sync_example.png" | link_to_img:"OperationStore client sync" }}

See the readme for [Relay support](https://github.com/rmosolgo/graphql-pro-js#use-with-relay), [Apollo Client support](https://github.com/rmosolgo/graphql-pro-js#use-with-apollo-client), and [plain JS usage](https://github.com/rmosolgo/graphql-pro-js#use-with-plain-javascript).



For help syncing in another language, you can take inspiration from the [JavaScript implementation](https://github.com/rmosolgo/graphql-pro-js), {% open_an_issue "Implementing operation sync in another language" %}, or email `support@graphql.pro`.

### Client Usage

`graphql-pro-js` generates [Apollo middleware](https://github.com/rmosolgo/graphql-pro-js#use-with-apollo-client) and a [Relay helper function](https://github.com/rmosolgo/graphql-pro-js#use-with-relay) to get started quickly.

To run stored operations from another client, send a param called `operationId` which is composed of:


```ruby
 {
   # ...
   operationId: "my-relay-app/ce79aa2784fc..."
   #            ^ client id  / ^ operation id
 }
```

The server will use those values to fetch an operation from the database.

#### Next Steps

Learn more about `OperationStore`'s [authentication]({{ site.baseurl }}/operation_store/authentication) or read some tips for [server management]({{ site.baseurl }}/operation_store/server_management).
