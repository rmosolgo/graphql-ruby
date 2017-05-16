---
layout: doc_stub
search: true
title: GraphQL::Execution::Multiplex
url: http://www.rubydoc.info/gems/graphql/GraphQL/Execution/Multiplex
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Execution/Multiplex
---

Class: GraphQL::Execution::Multiplex < Object
This class is part of a private API.
Execute multiple queries under the same multiplex "umbrella". They
can share a batching context and reduce redundant database hits. 
The flow is: 
- Multiplex instrumentation setup - Query instrumentation setup -
Analyze the multiplex + each query - Begin each query - Resolve lazy
values, breadth-first across all queries - Finish each query (eg,
get errors) - Query instrumentation teardown - Multiplex
instrumentation teardown 
If one query raises an application error, all queries will be in
undefined states. 
Validation errors and {GraphQL::ExecutionError}s are handled in
isolation: one of these errors in one query will not affect the
other queries. 
See Also:
- {Schema#multiplex} - for public API
Class methods:
begin_query, finish_query, run_all, run_queries
Instance methods:
initialize

