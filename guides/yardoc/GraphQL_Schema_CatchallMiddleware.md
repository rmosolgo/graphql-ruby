---
layout: doc_stub
search: true
title: GraphQL::Schema::CatchallMiddleware
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/CatchallMiddleware
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/CatchallMiddleware
---

Module: GraphQL::Schema::CatchallMiddleware
In early GraphQL versions, errors would be "automatically" rescued
and replaced with `"Internal error"`. That behavior was undesirable
but this middleware is offered for people who want to preserve it. 
It has a couple of differences from the previous behavior: 
- Other parts of the query _will_ be run (previously,
execution would stop when the error was raised and the result
would have no `"data"` key at all)
- The entry in Query::Context#errors is a GraphQL::ExecutionError,
_not_
the originally-raised error.
- The entry in the `"errors"` key includes the location of the field
which raised the errors.
Examples:
# Use CatchallMiddleware with your schema
# All errors will be suppressed and replaced with "Internal error" messages
MySchema.middleware << GraphQL::Schema::CatchallMiddleware
Class methods:
call

