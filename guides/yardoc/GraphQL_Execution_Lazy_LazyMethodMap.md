---
layout: doc_stub
search: true
title: GraphQL::Execution::Lazy::LazyMethodMap
url: http://www.rubydoc.info/gems/graphql/GraphQL/Execution/Lazy/LazyMethodMap
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Execution/Lazy/LazyMethodMap
---

Class: GraphQL::Execution::Lazy::LazyMethodMap < Object
This class is part of a private API.
GraphQL::Schema uses this to match returned values to lazy
resolution methods. Methods may be registered for classes, they
apply to its subclasses also. The result of this lookup is cached
for future resolutions. Instances of this class are thread-safe. 
See Also:
- {Schema#lazy?} - looks up values from this map
Instance methods:
find_superclass_method, get, initialize, initialize_copy, set

