# GraphQL::Pro JavaScript Client


JavaScript support for GraphQL projects using [graphql-pro](http://graphql.pro)'s `OperationStore` for persisted queries.

- [`sync` CLI](#sync-utility)
- [Relay support](#use-with-relay)
- [Apollo Client support](#use-with-apollo-client)
- [Plain JS support](#use-with-plain-javascript)
- [Authorization](#authorization)

See the [server-side docs on http://graphql-ruby.org](http://graphql-ruby.org/operation_store/overview)

## `sync` utility

This package contains a command line utility, `graphql-pro sync`:

```bash
$ graphql-pro sync # ...
Authorizing with HMAC
Syncing 4 operations to http://myapp.com/graphql/operations...
  3 added
  1 not modified
  0 failed
Generating client module in app/javascript/graphql/OperationStoreClient.js...
✓ Done!
```

`sync` Takes several options:

- `--url`
- `--path`
- `--client`
- `--secret`
- `--outfile`

You can see these and a few others with `graphql-pro sync --help`.

## Use with Relay

`graphql-pro` can persist queries from `relay-compiler` using the embedded `@relayHash` value.

To sync your queries with the server, use the `--path` option to point to your `__generated__` directory, for example:

```bash
# sync a Relay project
$ graphql-pro sync --path=src/__generated__  --outfile=src/OperationStoreClient.js --url=...
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
$ graphql-pro sync --path=src/graphql/ --url=...
```

Then, load the generated module and add its `.apolloMiddleware` to your network interface with `.use[...]`:

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

`OperationStore::Endpoint` uses HMAC-SHA256 to authorize requests.

Pass the key to `graphql-pro sync` as `--secret` to authorize it:

```bash
$ export MY_SECRET_KEY= "abcdefg..."
$ graphql-pro sync ... --secret=$MY_SECRET_KEY
# ...
Authorizing with HMAC
# ...
```

## Development

- Install dependencies `yarn install`
- Run the tests `yarn run test`
- Install for local development with `npm link .`
