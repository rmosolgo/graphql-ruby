---
layout: doc_stub
search: true
title: GraphQL::Schema::TimeoutMiddleware
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/TimeoutMiddleware
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/TimeoutMiddleware
---

Class: GraphQL::Schema::TimeoutMiddleware < Object
This middleware will stop resolving new fields after `max_seconds`
have elapsed. After the time has passed, any remaining fields will
be `nil`, with errors added to the `errors` key. Any
already-resolved fields will be in the `data` key, so you'll get a
partial response. 
You can provide a block which will be called with any timeout errors
that occur. 
Note that this will stop a query _in between_ field resolutions, but
it doesn't interrupt long-running `resolve` functions. Be sure to
use timeout options for external connections. For more info, see
www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/ 
Examples:
# Stop resolving fields after 2 seconds
MySchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2)
# Notifying Bugsnag on a timeout
MySchema.middleware << GraphQL::Schema::TimeoutMiddleware(max_seconds: 1.5) do |timeout_error, query|
Bugsnag.notify(timeout_error, {query_string: query_ctx.query.query_string})
end
Instance methods:
call, initialize, on_timeout

