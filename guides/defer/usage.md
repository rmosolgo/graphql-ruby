---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - Defer
title: Usage
desc: Using @defer on the client side
index: 2
pro: true
---


`@defer` is a [GraphQL directive](https://graphql.org/learn/queries/#directives) which instructs the server to execute the field in a special way:

```graphql
query GetPlayerInfo($handle: String!){
  player(handle: $handle) {
    name
    # Send this field later, to avoid slowing down the initial response:
    topScore(from: 2000, to: 2020) @defer
  }
}
```

The directives `@skip` and `@include` are built into any GraphQL server and client, but `@defer` requires special attention.

Apollo-Client has [experimental support](https://www.apollographql.com/docs/react/features/defer-support.html)
but it may [have some issues](https://github.com/apollographql/apollo-client/issues/4484), so you can try [this updated fork](https://github.com/rmosolgo/apollo-client) while they're worked out.

Want to use `@defer` with another client? Please {% open_an_issue "Client support for @defer with ..." %} or email `support@graphql.pro` and we'll dig in!

## Next Steps

{% internal_link "Set up your server", "/defer/setup" %} to support `@defer`.
