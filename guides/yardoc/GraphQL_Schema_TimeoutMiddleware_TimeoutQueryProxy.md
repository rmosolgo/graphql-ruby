---
layout: doc_stub
search: true
title: GraphQL::Schema::TimeoutMiddleware::TimeoutQueryProxy
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/TimeoutMiddleware/TimeoutQueryProxy
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/TimeoutMiddleware/TimeoutQueryProxy
---

Class: GraphQL::Schema::TimeoutMiddleware::TimeoutQueryProxy < Simpl...
This behaves like GraphQL::Query but #context returns the
_field-level_ context, not the query-level context. This means you
can reliably get the `irep_node` and `path` from it after the fact. 
Instance methods:
initialize

