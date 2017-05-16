---
layout: doc_stub
search: true
title: GraphQL::Schema::TypeMap
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/TypeMap
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/TypeMap
---

Class: GraphQL::Schema::TypeMap < Object
Stores `{ name => type }` pairs for a given schema. It behaves like
a hash except for a couple things:
- if you use `[key]` and that key isn't defined, 💥!
- if you try to define the same key twice, 💥!
If you want a type, but want to handle the undefined case, use
#fetch. 
Extended by:
Forwardable
Instance methods:
[], []=, initialize

