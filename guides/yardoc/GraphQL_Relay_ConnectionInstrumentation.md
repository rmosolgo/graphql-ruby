---
layout: doc_stub
search: true
title: GraphQL::Relay::ConnectionInstrumentation
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Relay/ConnectionInstrumentation
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Relay/ConnectionInstrumentation
---

Module: GraphQL::Relay::ConnectionInstrumentation
Provided a GraphQL field which returns a collection of nodes, wrap
that field to expose those nodes as a connection. 
The original resolve proc is used to fetch nodes, then a connection
implementation is fetched with BaseConnection.connection_for_nodes. 
Class methods:
instrument

