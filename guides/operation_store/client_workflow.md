# Client Workflow

To use persisted queries with your client application, you must:

- Set up `OperationStore`, as described in [Getting Started](/operation_store/getting_started)
- [Add the client](#add-a-client) to the system
- [Sync operations](#syncing) from the client to the server
- [Send `params[:operationId]`](#client-usage) from the client app

This documentation also touches on [graphql-ruby-client sync](/javascript_client/sync), a JavaScript client library for using `OperationStore`.

## Add a Client

Clients are registered via [the dashboard](/operation_store/getting_started#add-routes):

![Add a Client for Persisted Queries](/operation_store/add_a_client.png)

A default `secret` is provided for you, but you can also enter your own. The `secret` is used for [HMAC authentication](/operation_store/access_control).

(Are you interested in a Ruby API for this? Please [open an issue](https://github.com/rmosolgo/graphql-ruby/issues/new?title=OperationStore+Ruby+API&body=) or email `support@graphql.pro`.)

## Syncing

Once a client is registered, it can push queries to the server via [the Sync API](/operation_store/getting_started#add-routes).

The easiest way to sync is with `graphql-ruby-client sync`, a command-line tool written in JavaScript ([Sync Guide](/javascript_client/sync))

In short, it:

- Finds GraphQL queries from `.graphql` files or `relay-compiler` output in the provided `--path`
- Adds an [Authentication header](/operation_store/access_control) based on the provided `--client` and `--secret`
- Sends the operations to the provided `--url`
- Generates a JavaScript module into the provided `--outfile`

For example:

![OperationStore client sync](/operation_store/sync_example.png)

For help syncing in another language, you can take inspiration from the [JavaScript implementation](https://github.com/rmosolgo/graphql-ruby/tree/master/javascript_client), [open an issue](https://github.com/rmosolgo/graphql-ruby/issues/new?title=Implementing+operation+sync+in+another+language&body=), or email `support@graphql.pro`.

## Client Usage

See the [Sync Guide](/javascript_client/sync) for using OperationStore with Relay Modern, Apollo 1.x, Apollo Link, or plain JavaScript.

To run stored operations from another client, send a param called `operationId` which is composed of:


```ruby
 {
   # ...
   operationId: "my-relay-app/ce79aa2784fc..."
   #            ^ client id  / ^ operation id
 }
```

The server will use those values to fetch an operation from the database.

### Next Steps

Learn more about `OperationStore`'s [authentication](/operation_store/access_control) or read some tips for [server management](/operation_store/server_management).
