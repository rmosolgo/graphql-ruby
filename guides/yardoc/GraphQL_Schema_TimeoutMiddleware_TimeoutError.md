---
layout: doc_stub
search: true
title: GraphQL::Schema::TimeoutMiddleware::TimeoutError
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/TimeoutMiddleware/TimeoutError
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/TimeoutMiddleware/TimeoutError
---

Class: GraphQL::Schema::TimeoutMiddleware::TimeoutError < GraphQL::E...
This error is raised when a query exceeds `max_seconds`. Since it's
a child of GraphQL::ExecutionError, its message will be added to the
response's `errors` key. 
To raise an error that will stop query resolution, use a custom
block to take this error and raise a new one which _doesn't_ descend
from GraphQL::ExecutionError, such as `RuntimeError`. 
Instance methods:
initialize

