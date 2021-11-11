---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: graphql-ws and GraphiQL Subscription
desc: GraphQL subscriptions with graphql-ws client, like GraphiQL
index: 4
---

GraphQL-Ruby's JavaScript client includes 1 kind of support for [`graphql-ws`][graphql-ws], which is used by [GraphiQL][graphiql]:

- [ActionCable](#actioncable)

## ActionCable

`graphql-ruby-client` includes support for subscriptions when integrating [`graphql-ws`][graphql-ws] and [`@rails/actioncable][[rails-actioncable-client-side-component]].

To use it with GraphiQL:

```js
import * as React from 'react';
import ReactDOM from 'react-dom';
import { GraphiQL } from 'graphiql';
import { createGraphiQLFetcher } from '@graphiql/toolkit';
import ActionCableGraphqlWsClient from 'graphql-ruby-client/subscriptions/ActionCableGraphqlWsClient';
import { createConsumer } from '@rails/actioncable';

const cable = createConsumer()
const url = 'https://myschema.com/graphql';

const wsClient = new ActionCableGraphqlWsClient({
  cable
  // channelName: "GraphqlChannel" // Default
})

const fetcher = createGraphiQLFetcher({
  wsClient
});

export const App = () => <GraphiQL fetcher={fetcher} />;

ReactDOM.render(document.getElementByID('graphiql'), <App />);
```

[graphql-ws]: https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md
[graphiql]: https://github.com/graphql/graphiql
[rails-actioncable-client-side-component]: https://guides.rubyonrails.org/action_cable_overview.html#client-side-components