---
layout: doc_stub
search: true
title: GraphQL::Schema::Loader
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/Loader
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/Loader
---

Module: GraphQL::Schema::Loader
You can use the result of
GraphQL::Introspection::INTROSPECTION_QUERY to make a schema. This
schema is missing some important details like `resolve` functions,
but it does include the full type system, so you can use it to
validate queries. 
Extended by:
GraphQL::Schema::Loader
Class methods:
define_type, resolve_type
Instance methods:
load

