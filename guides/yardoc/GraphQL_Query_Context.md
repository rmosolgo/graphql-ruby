---
layout: doc_stub
search: true
title: GraphQL::Query::Context
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Query/Context
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Query/Context
---

Class: GraphQL::Query::Context < Object
Expose some query-specific info to field resolve functions. It
delegates `[]` to the hash that's passed to
`GraphQL::Query#initialize`. 
Extended by:
Forwardable
Instance methods:
[], []=, ast_node, initialize, namespace, skip, spawn, warden

