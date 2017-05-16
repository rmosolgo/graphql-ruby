---
layout: doc_stub
search: true
title: GraphQL::InternalRepresentation::Scope
url: http://www.rubydoc.info/gems/graphql/GraphQL/InternalRepresentation/Scope
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/InternalRepresentation/Scope
---

Class: GraphQL::InternalRepresentation::Scope < Object
At a point in the AST, selections may apply to one or more types.
Scope represents those types which selections may apply to. 
Scopes can be defined by: 
- A single concrete or abstract type - An array of types - `nil` 
The AST may be scoped to an array of types when two abstractly-typed
fragments occur in inside one another. 
Instance methods:
concrete_types, each, enter, initialize

