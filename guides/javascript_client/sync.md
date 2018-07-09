---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: OperationStore Sync
desc: Javascript tooling for persisted queries with GraphQL-Ruby
index: 1
---

JavaScript support for GraphQL projects using [graphql-pro](http://graphql.pro)'s `OperationStore` for persisted queries.

- [`sync` CLI](#sync-utility)
- [Relay support](#use-with-relay)
- [Apollo Client support](#use-with-apollo-client)
- [Apollo Link support](#use-with-apollo-link)
- [Plain JS support](#use-with-plain-javascript)
- [Authorization](#authorization)

See the {% internal_link "OperationStore guide", "/operation_store/overview" %} for server-side setup.

## `sync` utility

This package contains a command line utility, `graphql-ruby-client sync`:

```
$ graphql-ruby-client sync # ...
Authorizing with HMAC
Syncing 4 operations to http://myapp.com/graphql/operations...
  3 added
  1 not modified
  0 failed
Generating client module in app/javascript/graphql/OperationStoreClient.js...
✓ Done!
```

`sync` Takes several options:

option | description
--------|----------
`--url` | {% internal_link "Sync API", "/operation_store/getting_started.html#add-routes" %} url
`--path` | Local directory to search for `.graphql` / `.graphql.js` files
`--client` | Client ID ({% internal_link "created on server", "/operation_store/client_workflow" %})
`--secret` | Client Secret ({% internal_link "created on server", "/operation_store/client_workflow" %})
`--outfile` | Destination for generated JS code
`--add-typename` | Add `__typename` to all selection sets (for use with Apollo Client)

You can see these and a few others with `graphql-ruby-client sync --help`.

## Use with Relay

`graphql-ruby-client` can persist queries from `relay-compiler` using the embedded `@relayHash` value.

To sync your queries with the server, use the `--path` option to point to your `__generated__` directory, for example:

```bash
# sync a Relay project
$ graphql-ruby-client sync --path=src/__generated__  --outfile=src/OperationStoreClient.js --url=...
```

Then, the generated code may be integrated with Relay's [Network Layer](https://facebook.github.io/relay/docs/network-layer.html):

```js
// ...
// require the generated module:
const OperationStoreClient = require('./OperationStoreClient')

// ...
function fetchQuery(operation, variables, cacheConfig, uploadables) {
  const requestParams = {
    variables,
    operationName: operation.name,
  }

  if (process.env.NODE_ENV === "production")
    // In production, use the stored operation
    requestParams.operationId = OperationStoreClient.getOperationId(operation.name)
  } else {
    // In development, use the query text
    requestParams.query = operation.text,
  }

  return fetch('/graphql', {
    method: 'POST',
    headers: { /*...*/ },
    body: JSON.stringify(requestParams),
  }).then(/* ... */);
}

// ...
```

(Only Relay Modern is supported. Legacy Relay can't generate static queries.)

## Use with Apollo Client

Use the `--path` option to point at your `.graphql` files:

```
$ graphql-ruby-client sync --path=src/graphql/ --url=...
```

Then, load the generated module and add its `.apolloMiddleware` to your network interface with `.use([...])`:

```js
// load the generated module
var OperationStoreClient = require("./OperationStoreClient")

// attach it as middleware in production
// (in development, send queries to the server as normal)
if (process.env.NODE_ENV === "production") {
  MyNetworkInterface.use([OperationStoreClient.apolloMiddleware])
}
```

Now, the middleware will replace query strings with `operationId`s.

## Use with Apollo Link

Use the `--path` option to point at your `.graphql` files:

```
$ graphql-ruby-client sync --path=src/graphql/ --url=...
```

Then, load the generated module and add its `.apolloLink` to your Apollo Link:

```js
// load the generated module
var OperationStoreClient = require("./OperationStoreClient")

// Integrate the link to another link:
const link = ApolloLink.from([
  authLink,
  OperationStoreClient.apolloLink,
  httpLink,
])

// Create a client
const client = new ApolloClient({
  link: link,
  cache: new InMemoryCache(),
});
```

__Update the controller__: Apollo Link supports extra parameters _nested_ as `params[:extensions][:operationId]`, so update your controller to add that param to context:

```ruby
# app/controllers/graphql_controller.rb
context = {
  # ...
  # Support Apollo Link:
  operation_id: params[:extensions][:operationId]
}
```

Now, `context[:operation_id]` will be used to fetch a query from the database.

## Use with plain JavaScript

`OperationStoreClient.getOperationId` takes an operation name as input and returns the server-side alias for that operation:

```js
var OperationStoreClient = require("./OperationStoreClient")

OperationStoreClient.getOperationId("AppHomeQuery")       // => "my-frontend-app/7a8078c7555e20744cb1ff5a62e44aa92c6e0f02554868a15b8a1cbf2e776b6f"
OperationStoreClient.getOperationId("ProductDetailQuery") // => "my-frontend-app/6726a3b816e99b9971a1d25a1205ca81ecadc6eb1d5dd3a71028c4b01cc254c1"
```

Post the `operationId` in your GraphQL requests:

```js
// Lookup the operation name:
var operationId = OperationStoreClient.getOperationId(operationName)

// Include it in the params:
$.post("/graphql", {
  operationId: operationId,
  variables: queryVariables,
}, function(response) {
  // ...
})
```

## Authorization

`OperationStore` uses HMAC-SHA256 to {% internal_link "authenticate requests" , "/operation_store/access_control" %}.

Pass the key to `graphql-ruby-client sync` as `--secret` to authenticate it:

```bash
$ export MY_SECRET_KEY= "abcdefg..."
$ graphql-ruby-client sync ... --secret=$MY_SECRET_KEY
# ...
Authenticating with HMAC
# ...
```
