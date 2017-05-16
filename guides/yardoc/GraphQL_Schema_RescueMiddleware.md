---
layout: doc_stub
search: true
title: GraphQL::Schema::RescueMiddleware
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/RescueMiddleware
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/RescueMiddleware
---

Class: GraphQL::Schema::RescueMiddleware < Object
- Store a table of errors & handlers - Rescue errors in a middleware
chain, then check for a handler - If a handler is found, use it &
return a GraphQL::ExecutionError - If no handler is found, re-raise
the error 
Instance methods:
attempt_rescue, call, initialize, remove_handler, rescue_from

