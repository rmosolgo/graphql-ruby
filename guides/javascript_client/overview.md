# Overview

There is a JavaScript client for GraphQL-Ruby, `graphql-ruby-client`.

You can install it from NPM or Yarn:

```sh
yarn add graphql-ruby-client
# Or:
npm install graphql-ruby-client
```

The source code is [in the graphql-ruby repository](https://github.com/rmosolgo/graphql-ruby/tree/master/javascript_client).

See detailed guides for more info about its features:

- [sync CLI](javascript_client/sync) for use with [graphql-pro](https://graphql.pro)'s persisted query backend
- Subscription support:
  - [Apollo integration](/javascript_client/apollo_subscriptions)
  - [Relay integration](/javascript_client/relay_subscriptions)
  - [urql integration](/javascript_client/urql_subscriptions)
  - [GraphiQL integration](/javascript_client/graphiql_subscriptions)
