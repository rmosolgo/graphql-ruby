---
layout: doc_stub
search: true
title: GraphQL::Execution::Lazy
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Execution/Lazy
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Execution/Lazy
---

Class: GraphQL::Execution::Lazy < Object
This class is part of a private API.
This wraps a value which is available, but not yet calculated, like
a promise or future. 
Calling `#value` will trigger calculation & return the "lazy" value.
This is an itty-bitty promise-like object, with key differences: -
It has only two states, not-resolved and resolved - It has no
error-catching functionality 
Class methods:
resolve
Instance methods:
initialize, then, value

