---
layout: doc_stub
search: true
title: GraphQL::Schema::MiddlewareChain
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/MiddlewareChain
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/MiddlewareChain
---

Class: GraphQL::Schema::MiddlewareChain < Object
Given steps and arguments, call steps in order, passing
`(*arguments, next_step)`. 
Steps should call `next_step.call` to continue the chain, or _not_
call it to stop the chain. 
Extended by:
Forwardable
Instance methods:
<<, ==, add_middleware, get_arity, initialize, initialize_copy,
invoke, invoke_core, push, wrap

