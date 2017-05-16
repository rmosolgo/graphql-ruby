---
layout: doc_stub
search: true
title: GraphQL::Schema::BuildFromDefinition::ResolveMap
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/BuildFromDefinition/ResolveMap
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/BuildFromDefinition/ResolveMap
---

Class: GraphQL::Schema::BuildFromDefinition::ResolveMap < Object
This class is part of a private API.
Wrap a user-provided hash of resolution behavior for easy access at
runtime. 
Coerce scalar values by: - Checking for a function in the map like
`{ Date: { coerce_input: ->(val, ctx) { ... }, coerce_result:
->(val, ctx) { ... } } }` - Falling back to a passthrough 
Interface/union resolution can be provided as a `resolve_type:` key.
Instance methods:
call, coerce_input, coerce_result, initialize

