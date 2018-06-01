---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: Overview
desc: Getting Started with GraphQL-Ruby's Javascript client, graphql-ruby-client.
index: 0
---

There is a JavaScript client for GraphQL-Ruby, `graphql-ruby-client`.

You can install it from NPM or Yarn:

```
yarn add graphql-ruby-client
npm install graphql-ruby-client
```

The source code is [in the graphql-ruby repository](https://github.com/rmosolgo/graphql-ruby/tree/master/javascript_client).

See detailed guides for more info about its features:

- {% internal_link "sync CLI", "javascript_client/sync" %} for use with [graphql-pro](http://graphql.pro)'s persisted query backend
- Subscription support:
  - {% internal_link "Apollo integration", "/javascript_client/apollo_subscriptions" %}
  - {% internal_link "Relay integration", "/javascript_client/relay_subscriptions" %}
