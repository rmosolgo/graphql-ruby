---
layout: doc_stub
search: true
title: GraphQL::Schema::InstrumentedFieldMap
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/InstrumentedFieldMap
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/InstrumentedFieldMap
---

Class: GraphQL::Schema::InstrumentedFieldMap < Object
A two-level map with fields as the last values. The first level is
type names, which point to a second map. The second level is field
names, which point to fields. 
The catch is, the fields in this map _may_ have been modified by
being instrumented. 
Instance methods:
get, get_all, initialize, set

